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

  STATUS_CODE=$(curl -sSk  -o response_body.txt -w "%{http_code}" -X POST "$deployment_trigger_url" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $INPUT_KAPSTAN_API_KEY" \
    -d "$request_body")
  
  echo "Response Body: $(cat response_body.txt)"
  echo "Response Status Code: $STATUS_CODE"
  DEPLOYMENT_ID=$(cat response_body.txt | jq -r '.deployment_id')
  
  if [[ -z "$DEPLOYMENT_ID"  || $STATUS_CODE != 2* ]];
  then
    echo "Failed to deploy app, err: $(cat response_body.txt)"
    exit 1
  fi
  # echo "::set-output name=DEPLOYMENT_ID::$DEPLOYMENT_ID"
}


get_deployment_status(){
  deployment_status_url="https://api-dev.kapstan.io/external/organizations/${INPUT_ORGANIZATION_ID}/workspaces/$INPUT_ENVIRONMENT_ID/applications/${INPUT_APPLICATION_ID}/deployments/${DEPLOYMENT_ID}"
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

check_deployment_status(){
  for ((attempt=1; attempt<=MAX_ATTEMPTS; attempt++)); do
    echo "Attempt $attempt"
    
    get_deployment_status

    # Your command or action here
    # For example, check if a service is running
    if [[ $DEPLOYMENT_STATUS == "STAGE_COMPLETED" ]];
    then
        echo "Deployment completed"
        exit 0
    elif [[ $DEPLOYMENT_STATUS == "STAGE_FAILED"  || attempt == MAX_ATTEMPTS ]];
    then
        echo "Deployment failed"
        exit 1
    else
        echo "Waiting for $RETRY_WAIT_SECONDS seconds before next attempt."
        sleep $RETRY_WAIT_SECONDS
    fi
  done
}

# defaults
MAX_ATTEMPTS=${INPUT_MAX_ATTEMPTS:-1}
RETRY_WAIT_SECONDS=${INPUT_RETRY_WAIT_SECONDS:-2}

deployment_application
check_deployment_status

