#!/bin/bash

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
ROLE_NAME="lambda-api-role"
FUNCTION_NAME="HelloApiFunction"
API_NAME="HelloApiGateway"

# 1. Delete Lambda function
aws lambda delete-function --function-name $FUNCTION_NAME

# 2. Detach and delete IAM role and policy
aws iam delete-role-policy \
  --role-name $ROLE_NAME \
  --policy-name lambda-logs

aws iam delete-role --role-name $ROLE_NAME

# 3. Find API Gateway ID by name
REST_API_ID=$(aws apigateway get-rest-apis \
  --query "items[?name=='$API_NAME'].id" \
  --output text)

# 4. Delete API Gateway if it exists
if [ -n "$REST_API_ID" ]; then
  aws apigateway delete-rest-api --rest-api-id $REST_API_ID
else
  echo "API Gateway '$API_NAME' not found or already deleted."
fi

# 5. Delete zip if exists
rm -f function.zip

echo "✅ All resources cleaned up."
