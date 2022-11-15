import json, boto3,os, sys, uuid
from urllib.parse import unquote_plus

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    some_text = "test"
    bucket_name = "my-tf-test-bucket-for-python-begginer"
    file_names = ["index.html", "error.html"]
    s3_paths = []
    for file_name in file_names:
        lambda_path = file_name
        s3_paths.append (file_name)
        s3 = boto3.resource("s3")
        s3.meta.client.upload_file(lambda_path, bucket_name, file_name, ExtraArgs={'ContentType': "text/html"})

    return {
        'statusCode': 200,
        'body': json.dumps('file is created in:'+str(s3_paths))
    }