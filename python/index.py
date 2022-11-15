import json, boto3,os, sys, uuid
from urllib.parse import unquote_plus
import requests
import base64

random_pic_api = "https://picsum.photos/1280/720"

def lambda_handler(event, context):

    response = requests.get(random_pic_api)
    return {
        'headers':{ "Content-Type": response.headers['content-type'], "Content-Length": len(response.content), },
        'statusCode': 200,
        'body': base64.b64encode(response.content).decode('utf-8'),
        'isBase64Encoded': True
    }