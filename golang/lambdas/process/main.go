package main

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"image"

	"image/gif"
	_ "image/jpeg"
	"io"
	"log"
	"os"

	"github.com/andybons/gogif"
	"golang.org/x/image/draw"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

var client *s3.Client
var bucket_name string

func init() {
	bucket_name = os.Getenv("BUCKET_NAME")

	cfg, err := config.LoadDefaultConfig(context.TODO())

	if err != nil {
		log.Fatal(err)
	}
	client = s3.NewFromConfig(cfg)
}

func main() {
	lambda.Start(HandleRequest)
}

type gif_request struct {
	Images []string `json:"images"`
	Output string   `json:"output"`
	Delays []int    `json:"delays"`
}

func processMsg(data *gif_request) (*bytes.Buffer, error) {

	var images []*image.Paletted

	var rect image.Rectangle
	skip := false

	for idx, image_key := range data.Images {
		obj, err := client.GetObject(context.TODO(), &s3.GetObjectInput{
			Bucket: aws.String(bucket_name),
			Key:    aws.String("input/" + image_key),
		})
		if err != nil {
			log.Println("could not get object", err)
			return nil, err
		}

		obj_body := make([]byte, obj.ContentLength)
		total := 0
		for {
			n, err := obj.Body.Read(obj_body[total:])
			total += n
			if err == io.EOF {
				break
			}
		}
		img, _, err := image.Decode(bytes.NewReader(obj_body))
		if err != nil {
			log.Println("Failed decode", err)
			return nil, err
		}

		if !skip {
			rect = img.Bounds()
			skip = true
		}

		palettedImage := image.NewPaletted(rect, nil)
		quantizer := gogif.MedianCutQuantizer{NumColor: 64}
		quantizer.Quantize(palettedImage, rect, img, image.Point{0, 0})

		draw.CatmullRom.Scale(palettedImage, palettedImage.Rect, img, img.Bounds(), draw.Over, nil)

		images = append(images, palettedImage)
		log.Println("Image no", idx, "size:", total)
	}

	log.Println("Total images to merge", len(images))

	var b bytes.Buffer
	buf_writer := bufio.NewWriter(&b)

	return &b, gif.EncodeAll(buf_writer, &gif.GIF{
		Image: images,
		Delay: data.Delays,
	})
}

func HandleRequest(ctx context.Context, sqsEvent events.SQSEvent) error {

	for _, msg := range sqsEvent.Records {

		log.Println("Received request:", msg.Body)

		var data gif_request
		if err := json.Unmarshal([]byte(msg.Body), &data); err != nil {
			log.Println(err)
			continue
		}

		output, err := processMsg(&data)
		if err != nil {
			log.Println(err)
			continue
		}

		_, err = client.PutObject(context.TODO(), &s3.PutObjectInput{
			Bucket:        aws.String(bucket_name),
			Key:           aws.String("output/" + data.Output),
			Body:          output,
			ContentLength: int64(output.Len()),
		})
		if err != nil {
			log.Panicln(err)
			continue
		}
	}
	return nil
}
