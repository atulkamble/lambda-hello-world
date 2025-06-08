'#!/bin/bash

# Create IAM Role
aws iam create-role \
  --role-name lambda-basic-role \
  --assume-role-policy-document file://trust-policy.json

# Attach Policy to Role
aws iam put-role-policy \
  --role-name lambda-basic-role \
  --policy-name lambda-basic-logs \
  --policy-document file://role-policy.json

# Wait for IAM role to propagate
sleep 10

# Zip the function code
zip function.zip lambda_function.py

# Create Lambda Function
aws lambda create-function \
  --function-name HelloWorldFunction \
  --runtime python3.12 \
  --role arn:aws:iam::535002879962:role/lambda-basic-role \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://function.zip
