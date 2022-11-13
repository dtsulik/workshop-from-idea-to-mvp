package main

import (
	"context"
	"encoding/base64"
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

func HandleRequest(ctx context.Context, request events.LambdaFunctionURLRequest) (events.LambdaFunctionURLResponse, error) {

	output, err := client.ListObjectsV2(ctx, &s3.ListObjectsV2Input{
		Bucket: aws.String(bucket_name),
	})

	if err != nil {
		log.Fatal(err)
	}

	log.Println("first page results:")
	var obj_body []byte
	total := 0
	for _, object := range output.Contents {
		log.Printf("key=%s size=%d\n", *object.Key, object.Size)
		obj, err := client.GetObject(ctx, &s3.GetObjectInput{
			Bucket: aws.String(bucket_name),
			Key:    object.Key,
		})
		if err != nil {
			log.Fatal(err)
		}
		obj_body = make([]byte, obj.ContentLength)
		for {
			n, err := obj.Body.Read(obj_body[total:])
			total += n
			if err == io.EOF {
				break
			}
		}
		log.Println("Read total", total, "bytes of", *object.Key, "with length", obj.ContentLength)
	}

	return events.LambdaFunctionURLResponse{Body: base64.StdEncoding.EncodeToString(obj_body[:total]),
			StatusCode: 200, IsBase64Encoded: true,
			Headers: map[string]string{"Content-Type": "image/png"}},
		nil
}
