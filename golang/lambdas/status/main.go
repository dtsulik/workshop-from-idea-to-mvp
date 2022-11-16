package main

import (
	"context"

	"github.com/aws/aws-lambda-go/lambda"
)

func init() {
	status_map = make(map[string]string)
}

func main() {
	lambda.Start(HandleRequest)
}

type status_event_t struct {
	status_type string
	request_id  string
	status      string
}

var status_map map[string]string

func HandleRequest(ctx context.Context, request status_event_t) (status_event_t, error) {

	if request.status_type == "check" {
		return status(request.request_id)
	}

	status_map[request.request_id] = request.status

	return request, nil
}

func status(request_id string) (status_event_t, error) {
	if _, ok := status_map[request_id]; !ok {
		return status_event_t{
			request_id: request_id,
			status:     "NOT_FOUND",
		}, nil
	}

	return status_event_t{
		request_id: request_id,
		status:     status_map[request_id],
	}, nil
}
