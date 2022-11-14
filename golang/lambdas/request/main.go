package main

import (
	"context"
	"encoding/json"
	"log"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
)

var client *sqs.Client
var queue_url string

func init() {
	queue_url = os.Getenv("QUEUE_URL")
	cfg, err := config.LoadDefaultConfig(context.TODO())

	if err != nil {
		log.Fatal(err)
	}
	client = sqs.NewFromConfig(cfg)
}

func main() {
	lambda.Start(HandleRequest)
}

func HandleRequest(ctx context.Context, request events.LambdaFunctionURLRequest) (events.LambdaFunctionURLResponse, error) {

	if len(request.Body) == 0 {
		return events.LambdaFunctionURLResponse{Body: "Expecting a message", StatusCode: 418}, nil
	}

	var data map[string]interface{}
	if err := json.Unmarshal([]byte(request.Body), &data); err != nil {
		return events.LambdaFunctionURLResponse{Body: "Invalid JSON", StatusCode: 400}, nil
	}

	_, images_check := data["images"]
	_, output_check := data["output"]
	_, delays_check := data["delays"]

	if !images_check || !output_check || !delays_check {
		return events.LambdaFunctionURLResponse{Body: "Expecting \"images\", \"delays\" and \"output\" fields",
			StatusCode: 400}, nil
	}

	_, err := client.SendMessage(context.TODO(), &sqs.SendMessageInput{
		QueueUrl:    aws.String(queue_url),
		MessageBody: aws.String(request.Body),
	})

	if err != nil {
		log.Println(err)
		return events.LambdaFunctionURLResponse{Body: "Error submitting request", StatusCode: 500}, nil
	}

	return events.LambdaFunctionURLResponse{Body: "OK", StatusCode: 200}, nil
}
