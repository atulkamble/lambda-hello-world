#!/bin/bash

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
ROLE_NAME="lambda-api-role"
FUNCTION_NAME="HelloApiFunction"
API_NAME="HelloApiGateway"

# 1. Create IAM Role
aws iam create-role \
  --role-name $ROLE_NAME \
  --assume-role-policy-document file://trust-policy.json

aws iam put-role-policy \
  --role-name $ROLE_NAME \
  --policy-name lambda-logs \
  --policy-document file://role-policy.json

# 2. Zip the Lambda function
zip function.zip lambda_function.py

# 3. Create Lambda Function
sleep 10
aws lambda create-function \
  --function-name $FUNCTION_NAME \
  --runtime python3.12 \
  --role arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://function.zip \
  --region $REGION

# 4. Create API Gateway REST API
REST_API_ID=$(aws apigateway create-rest-api \
  --name "$API_NAME" \
  --query 'id' \
  --output text)

# 5. Get Root Resource ID
PARENT_ID=$(aws apigateway get-resources \
  --rest-api-id $REST_API_ID \
  --query 'items[?path==`/`].id' \
  --output text)

# 6. Create /hello resource
RESOURCE_ID=$(aws apigateway create-resource \
  --rest-api-id $REST_API_ID \
  --parent-id $PARENT_ID \
  --path-part hello \
  --query 'id' \
  --output text)

# 7. Create GET method on /hello
aws apigateway put-method \
  --rest-api-id $REST_API_ID \
  --resource-id $RESOURCE_ID \
  --http-method GET \
  --authorization-type "NONE"

# 8. Integrate with Lambda
aws apigateway put-integration \
  --rest-api-id $REST_API_ID \
  --resource-id $RESOURCE_ID \
  --http-method GET \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:$ACCOUNT_ID:function:$FUNCTION_NAME/invocations

# 9. Grant API Gateway permission to invoke Lambda
aws lambda add-permission \
  --function-name $FUNCTION_NAME \
  --statement-id apigateway-test-2 \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn arn:aws:execute-api:$REGION:$ACCOUNT_ID:$REST_API_ID/*/GET/hello

# 10. Deploy API
aws apigateway create-deployment \
  --rest-api-id $REST_API_ID \
  --stage-name prod

# 11. Output URL
echo "API endpoint:"
echo "https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/prod/hello?name=Atul"
