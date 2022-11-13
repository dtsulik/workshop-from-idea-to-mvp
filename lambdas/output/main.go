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

	if len(request.RawPath) == 0 {
		return events.LambdaFunctionURLResponse{Body: "Please provide object key.", StatusCode: 418}, nil
	}

	obj, err := client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(bucket_name),
		Key:    aws.String("output/" + request.RawPath),
	})
	if err != nil {
		log.Fatal(err)
		return events.LambdaFunctionURLResponse{Body: "Object not found", StatusCode: 400}, nil
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
	log.Println("Read total", total, "bytes of", request.RawPath, "with length", obj.ContentLength)

	return events.LambdaFunctionURLResponse{Body: base64.StdEncoding.EncodeToString(obj_body[:total]),
			StatusCode: 200, IsBase64Encoded: true,
			Headers: map[string]string{"Content-Type": "image/gif"}},
		nil
}
