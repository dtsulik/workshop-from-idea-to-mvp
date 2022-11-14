# Using AWS SDK for Node JS

## Setup
To use the AWS SDK for Node JS, you must first install the SDK. You can install the SDK using npm.

```bash
npm install aws-sdk
```

## Write a Lambda function for s3 event
```javascript
const AWS = require('aws-sdk');
const s3 = new AWS.S3();

exports.handler = async (event) => {
	// Your code goes here!
};
```

## Test a Lambda function
To test a Lambda function, you must first create a test event. The test event is a JSON document that contains the input data for your Lambda function. You can create a test event using the AWS Management Console or the AWS CLI.

## Deploy a Lambda function
To deploy a Lambda function, you must first create a deployment package. The deployment package is a ZIP archive that contains your Lambda function code and any dependencies. You can create a deployment package using the AWS Management Console or the AWS CLI.

### Create a deployment package using the AWS Management Console
To create a deployment package using the AWS Management Console, you must first create a function. You can create a function using the AWS Management Console.

### Download a deployment package using the AWS Management Console
Download a deployment package and upload it with Terraform.
