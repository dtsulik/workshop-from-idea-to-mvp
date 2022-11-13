package main

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"image"
	"image/color/palette"
	"image/draw"
	"image/gif"
	"io"
	"log"
	"os"

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

	images := make([]*image.Paletted, len(data.Images))

	for idx, image_key := range data.Images {
		obj, err := client.GetObject(context.TODO(), &s3.GetObjectInput{
			Bucket: aws.String(bucket_name),
			Key:    aws.String(image_key),
		})
		if err != nil {
			log.Println(err)
			continue
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
			log.Println(err)
			continue
		}

		palettedImage := image.NewPaletted(img.Bounds(), palette.Plan9)
		draw.Draw(palettedImage, palettedImage.Rect, img, img.Bounds().Min, draw.Over)

		images = append(images, palettedImage)
		log.Println("Image no", idx, "size:", total)
	}

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
			log.Panicln(err)
			continue
		}

		output, err := processMsg(&data)
		if err != nil {
			log.Panicln(err)
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
