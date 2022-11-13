package main

import (
	"bytes"
	"context"
	"encoding/base64"
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

	if !request.IsBase64Encoded || len(request.Body) == 0 {
		return events.LambdaFunctionURLResponse{Body: "Expecting a file", StatusCode: 418}, nil
	}

	filename, ok := request.Headers["filename"]
	if !ok {
		return events.LambdaFunctionURLResponse{Body: "Expecting a \"filename\" header", StatusCode: 400}, nil
	}

	file, err := base64.StdEncoding.DecodeString(request.Body)
	if err != nil {
		log.Println(err)
		return events.LambdaFunctionURLResponse{Body: "Failed to decode", StatusCode: 500}, nil
	}

	_, err = client.PutObject(context.TODO(), &s3.PutObjectInput{
		Bucket:        aws.String(bucket_name),
		Key:           aws.String("input/" + filename),
		Body:          bytes.NewReader(file),
		ContentLength: int64(len(file)),
	})

	if err != nil {
		log.Println("Couldn't upload file: " + err.Error())
		return events.LambdaFunctionURLResponse{Body: "Failed to upload to s3", StatusCode: 500}, nil
	}

	return events.LambdaFunctionURLResponse{Body: "OK", StatusCode: 200}, nil
}
