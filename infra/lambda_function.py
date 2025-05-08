import uuid
import hashlib
import json
import boto3
import time
from random import sample as random_sample

BASE62 = '$E!*;RKjVs4NPpq9algi85u1zefGFm3TvUxH6wnLrbQdSJCkZcyXWthMAo2DYB'
puddling = "I70"

# Initialize DynamoDB client if needed
dynamodb = boto3.resource('dynamodb')

table = dynamodb.Table('ShortenedURLs')


def encode_base62(num):
    """Encode a number to a Base62 string."""
    if num == 0:
        return BASE62[0]
    encoded = []
    while num > 0:
        num, remainder = divmod(num, 62)
        encoded.append(BASE62[remainder])
    encoded_short_link = ''.join(reversed(encoded))
    full_short_url = f"{encoded_short_link[:len(encoded_short_link)]}"
    return full_short_url


def generate_short_link(uuid_str):
    hash_object = hashlib.sha256(uuid_str.encode())
    hash_hex = hash_object.hexdigest()  # Get the hexadecimal representation of the hash

    short_id = encode_base62(int(hash_hex[:16], 16))  # Take a slice and convert to base62

    return short_id[:7]


def lambda_handler_POST(event, context):
    try:
        uuid_str = str(uuid.uuid4())  # Generates a random UUID

        body = json.loads(event["body"])
        original_url = body.get("original_url")

        if not original_url:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "original_url is required"})
            }

        short_link = generate_short_link(uuid_str)
        expiration_time = int(time.time()) + 3600  # Expires in 1 hour

        table.put_item(Item={
            'short_url': short_link,
            'original_url': original_url,
            'usage_count': 0,
            'expiration_time': expiration_time  # TTL attribute
        })

        # Step 4: Return the response (can be adjusted as needed)
        response = {
            "statusCode": 200,
            "headers": {
            "Access-Control-Allow-Origin": "*",  # Allow all origins or specify your frontend domain
            "Access-Control-Allow-Methods": "OPTIONS,POST",
            "Access-Control-Allow-Headers": "Content-Type",
            },
            "body": json.dumps({
                "original_uuid": uuid_str,
                "short_link": short_link,
                'original_url': original_url,
                'usage_count': 0
            })
        }

        return response
    except Exception as e:
        return {
            "statusCode": 555,
            "body": json.dumps({"error": str(e)})
        }


def lambda_handler_GET(event, context):
    # Extract the path parameter from API Gateway event
    path_params = event.get("pathParameters", {})
    short_url = path_params.get("short_url", "")

    # Lookup the original URL
    curr_item = table.get_item(Key={'short_url': short_url}).get('Item', {})
    original_url = curr_item.get('original_url')

    if original_url:
        table.update_item(
            Key={'short_url': short_url},
            UpdateExpression="SET usage_count = usage_count + :inc",
            ExpressionAttributeValues={':inc': 1},
            ReturnValues="UPDATED_NEW"
        )
        return {
            "statusCode": 302,  # HTTP 302 Found (Redirect)
            "headers": {
                "Location": original_url
            }
        }
    else:
        return {
            "statusCode": 404,
            "body": json.dumps({"error": "Short URL not found"})
        }
