#!/bin/bash

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"

# Lambda Functions
FUNCTIONS=("HelloApiFunction" "HelloWorldFunction")

# IAM Roles
ROLES=("lambda-api-role" "lambda-basic-role")

# Delete Lambda functions
for FUNCTION_NAME in "${FUNCTIONS[@]}"; do
  echo "Deleting Lambda function: $FUNCTION_NAME"
  aws lambda delete-function --function-name "$FUNCTION_NAME"
done

# Delete IAM roles and attached policy
for ROLE_NAME in "${ROLES[@]}"; do
  echo "Detaching policies and deleting IAM role: $ROLE_NAME"
  aws iam detach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole 2>/dev/null

  aws iam delete-role --role-name "$ROLE_NAME"
done

# Delete API Gateway
API_NAME="HelloApiGateway"
REST_API_ID=$(aws apigateway get-rest-apis \
  --query "items[?name=='$API_NAME'].id" \
  --output text)

if [ -n "$REST_API_ID" ]; then
  echo "Deleting API Gateway: $API_NAME"
  aws apigateway delete-rest-api --rest-api-id "$REST_API_ID"
else
  echo "API Gateway '$API_NAME' not found or already deleted."
fi

# Delete Lambda zip file
rm -f function.zip

echo "✅ All Lambda-related resources have been deleted."
