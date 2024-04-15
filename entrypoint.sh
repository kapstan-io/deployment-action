#!/bin/bash

# Function to trigger application deployment
deployment_application() {
  deployment_trigger_url="https://api-dev.kapstan.io/external/organizations/${INPUT_ORGANIZATION_ID}/workspaces/$INPUT_ENVIRONMENT_ID/applications/${INPUT_APPLICATION_ID}/deploy"

  # Build the JSON request body
  request_body=$(cat <<EOF
{ 
  "imageTag": "$INPUT_IMAGE_TAG",
  "imageRepositoryName": "$INPUT_IMAGE_REPOSITORY_NAME",
  "comment": "Reason: Trigger by action ${GITHUB_EVENT_NAME} on ${GITHUB_REF_NAME} in ${GITHUB_REPOSITORY}"
}
EOF
)

  echo "API URL: $deployment_trigger_url"
  echo "Request Body: $request_body"

  status_code=$(curl -sSk  -o response_body.txt -w "%{http_code}" -X POST "$deployment_trigger_url" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $INPUT_KAPSTAN_API_KEY" \
    -d "$request_body")
  
  echo "Response Status Code: $status_code"
  echo "Response Body: $(cat response_body.txt)"
  DEPLOYMENT_ID=$(cat response_body.txt | jq -r '.deployment_id')
  echo "::set-output name=DEPLOYMENT_ID::$DEPLOYMENT_ID"
}


get_deployment_status(){
  deployment_status_url="https://api-dev.kapstan.io/external/organizations/${INPUT_ORGANIZATION_ID}/workspaces/$INPUT_ENVIRONMENT_ID/applications/${INPUT_APPLICATION_ID}/deployments/${INPUT_DEPLOYMENT_ID}"
  echo "API URL: $deployment_status_url"
  status_code=$(curl -sSk  -o response_body.txt -w "%{http_code}" "$deployment_status_url" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $INPUT_KAPSTAN_API_KEY")

  response_body=$(cat response_body.txt)
  echo "Status Code: $status_code"
  echo "Response Body: $response_body"
  DEPLOYMENT_STATUS=$(cat response_body.txt | jq -r '.stage')
  echo "Deployment Status: $DEPLOYMENT_STATUS"
  rm response_body.txt
}

echo "Action - $INPUT_ACTION"
case $INPUT_ACTION in
  "deploy-app")
    deployment_application
    ;;
  "get-deployment-status")
    get_deployment_status
    ;;
esac