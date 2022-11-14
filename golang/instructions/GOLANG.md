# Using AWS SDK for Golang v2

## Setup
To get started with the AWS SDK for Go, you need to install Go and configure your Go development environment. For information about installing Go, see the [Getting Started](https://golang.org/doc/install) page. For information about configuring your Go development environment, see the [How to Write Go Code](https://golang.org/doc/code.html) page.

## Initialize go module
```bash
go mod init github.com/yourname/yourproject
```
or if not using github
```bash
go mod init yourproject
```

## Install the AWS SDK for Go
```bash
go get github.com/aws/aws-sdk-go-v2
```

## Create a file named `main.go` and add the following code
```go
package main

func main() {
	lambda.Start(HandleRequest)
}
func HandleRequest(ctx context.Context, request events.LambdaFunctionURLRequest) (events.LambdaFunctionURLResponse, error) {

}
```
This is our basic lambda handler. To use it add following to import.
```go
    ...
    "github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
    ...
```

Since we are working directly with lambda funtion URLs we have following available in `events` package.
```go
type LambdaFunctionURLRequest struct {
	Version               string                          `json:"version"` // Version is expected to be `"2.0"`
	RawPath               string                          `json:"rawPath"`
	RawQueryString        string                          `json:"rawQueryString"`
	Cookies               []string                        `json:"cookies,omitempty"`
	Headers               map[string]string               `json:"headers"`
	QueryStringParameters map[string]string               `json:"queryStringParameters,omitempty"`
	RequestContext        LambdaFunctionURLRequestContext `json:"requestContext"`
	Body                  string                          `json:"body,omitempty"`
	IsBase64Encoded       bool                            `json:"isBase64Encoded"`
}
```
For API Gateway proxy integration:
```go
type APIGatewayV2HTTPRequest struct {
	Version               string                         `json:"version"`
	RouteKey              string                         `json:"routeKey"`
	RawPath               string                         `json:"rawPath"`
	RawQueryString        string                         `json:"rawQueryString"`
	Cookies               []string                       `json:"cookies,omitempty"`
	Headers               map[string]string              `json:"headers"`
	QueryStringParameters map[string]string              `json:"queryStringParameters,omitempty"`
	PathParameters        map[string]string              `json:"pathParameters,omitempty"`
	RequestContext        APIGatewayV2HTTPRequestContext `json:"requestContext"`
	StageVariables        map[string]string              `json:"stageVariables,omitempty"`
	Body                  string                         `json:"body,omitempty"`
	IsBase64Encoded       bool                           `json:"isBase64Encoded"`
}
```

From both of these we will be interested in same fields.
```go
    ...
    Headers               map[string]string              `json:"headers"`
    ...
	Body                  string                         `json:"body,omitempty"`
	IsBase64Encoded       bool                           `json:"isBase64Encoded"`
    ...
```

## Writing our handler

Let's add code for our handler.

Some basic checks before we process the request. When receiving a file lambda will send it as base64 encoded string.
```go
func HandleRequest(ctx context.Context, request events.LambdaFunctionURLRequest) (events.LambdaFunctionURLResponse, error) {
	if !request.IsBase64Encoded || len(request.Body) == 0 {
		return events.LambdaFunctionURLResponse{Body: "Expecting a file", StatusCode: 418}, nil
	}
    ...
}
```

We will also add custom logic to request by requiring `filename` header.
```go
    ...
	filename, ok := request.Headers["filename"]
	if !ok {
		return events.LambdaFunctionURLResponse{Body: "Expecting a \"filename\" header", StatusCode: 400}, nil
	}
    ...
```

Let's decode the payload
```go
    ...
	file, err := base64.StdEncoding.DecodeString(request.Body)
	if err != nil {
		log.Println(err)
		return events.LambdaFunctionURLResponse{Body: "Failed to decode", StatusCode: 500}, nil
	}
    ...
```

At this point we are ready to write the payload to S3. Before we go there let's add s3 config:
```go
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
```

Reason we do this in init() function is because we want to load config only once. This is a good practice when working with lambda. Read more about it [here](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html). Read more about golang init function [here](https://golang.org/doc/effective_go#init).

TLDR: init() function is called before main() function. It is only called once in the lifetime of the program.

To make use of above add these to import:
```go
    ...
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
    ...
```

Now that we have S3 sorted initialized let's PUT the file to S3.
```go
    ...
    _, err = client.PutObject(context.TODO(), &s3.PutObjectInput{
        Bucket: aws.String(bucket_name),
        Key:    aws.String(filename),
        Body:   bytes.NewReader(file),
    })
    if err != nil {
        log.Println(err)
        return events.LambdaFunctionURLResponse{Body: "Failed to upload", StatusCode: 500}, nil
    }
    ...
```

If there are no errors we can return a success message. `LambdaFunctionURLResponse` provides us with following:
```go
type LambdaFunctionURLResponse struct {
	StatusCode      int               `json:"statusCode"`
	Headers         map[string]string `json:"headers"`
	Body            string            `json:"body"`
	IsBase64Encoded bool              `json:"isBase64Encoded"`
	Cookies         []string          `json:"cookies"`
}
```
Currently we need to set `StatusCode` and `Body`. 
```go
    ...
    return events.LambdaFunctionURLResponse{Body: "Success", StatusCode: 200}, nil
}
```

End result should look like this:
```go
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
```
