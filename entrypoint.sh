#!/bin/bash

INPUT_APPLICATION_NAME="$1"
INPUT_IMAGE_TAG="$2"
INPUT_PRE_DEPLOY_IMAGE_TAG="$3"
INPUT_KAPSTAN_API_KEY="$4"
INPUT_WAIT_FOR_DEPLOYMENT="$5"
INPUT_CONTAINERS_JSON="$6"


kapstan_api_base_url="https://localhost:5050/v2/external"
filePath="/tmp/response.txt"

# Function to trigger application deployment
deployment_application() {
  deployment_trigger_url="$kapstan_api_base_url/applications/${INPUT_APPLICATION_NAME}/deploy"

  # Build the JSON request body
  request_body=$(cat <<EOF
{ 
  "imageTag": "$INPUT_IMAGE_TAG",
  "comment": "Deployment triggered by action ${GITHUB_EVENT_NAME} on ${GITHUB_REF_NAME} in ${GITHUB_REPOSITORY}",
  "preDeployImageTag": "$INPUT_PRE_DEPLOY_IMAGE_TAG",
  "containers": $INPUT_CONTAINERS_JSON
}
EOF
)

  echo "API URL: $deployment_trigger_url"
  echo "Request Body: $request_body"

  STATUS_CODE=$(curl -sSk  -o $filePath -w "%{http_code}" -X POST "$deployment_trigger_url" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $INPUT_KAPSTAN_API_KEY" \
    -d "$request_body")
  
  echo "Response Body: $(cat $filePath)"
  echo "Response Status Code: $STATUS_CODE"
  DEPLOYMENT_ID=$(cat $filePath | jq -r '.deployment_id')
  
  if [[ -z "$DEPLOYMENT_ID"  || $STATUS_CODE != 2* ]];
  then
    echo "Failed to deploy app, err: $(cat $filePath)"
    exit 1
  fi
  echo "KAPSTAN_DEPLOYMENT_ID=$DEPLOYMENT_ID" >> "${GITHUB_ENV}"
  rm $filePath
}


get_deployment_status(){
  deployment_status_url="$kapstan_api_base_url/applications/${INPUT_APPLICATION_NAME}/deployments/${DEPLOYMENT_ID}"
  echo "API URL: $deployment_status_url"
  status_code=$(curl -sSk  -o $filePath -w "%{http_code}" "$deployment_status_url" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $INPUT_KAPSTAN_API_KEY")

  response_body=$(cat $filePath)
  echo "Status Code: $status_code"
  echo "Response Body: $response_body"
  DEPLOYMENT_STATUS=$(cat $filePath | jq -r '.stage')
  echo "Deployment Status: $DEPLOYMENT_STATUS"
  echo "KAPSTAN_DEPLOYMENT_STATUS=$DEPLOYMENT_STATUS" >> "${GITHUB_ENV}"
  rm $filePath
}

check_deployment_status(){
  for ((attempt=1; attempt<=MAX_ATTEMPTS; attempt++)); do
    echo "Attempt $attempt"
    
    # fetch deployment status
    get_deployment_status

    # keep checking if the status is completed or not, otherwise exit 1
    if [[ $DEPLOYMENT_STATUS == "STAGE_COMPLETED" ]];
    then
        echo "KAPSTAN_DEPLOYMENT_MESSAGE='Deployment completed for application: $INPUT_APPLICATION_NAME'" >> "$GITHUB_ENV"
        exit 0
    elif [[ $DEPLOYMENT_STATUS == "STAGE_FAILED" ]];
    then
        echo "KAPSTAN_DEPLOYMENT_MESSAGE='Deployment failed'" >> "$GITHUB_ENV"
        exit 1
    elif [[ $attempt == $MAX_ATTEMPTS ]];
    then 
        echo "KAPSTAN_DEPLOYMENT_MESSAGE='Failed to get deployment status, exiting after max_attempt reached, last known status: $DEPLOYMENT_STATUS'" >> "$GITHUB_ENV"
    else
        echo "Waiting for $RETRY_WAIT_SECONDS seconds before next attempt."
        sleep $RETRY_WAIT_SECONDS
    fi
  done
}

cleanup(){
  rm -rf $filePath
}

# defaults
MAX_ATTEMPTS=${INPUT_MAX_ATTEMPTS:-5}
RETRY_WAIT_SECONDS=${INPUT_RETRY_WAIT_SECONDS:-15}

MIN_RETRY_WAIT_SECONDS=15
(( RETRY_WAIT_SECONDS < MIN_RETRY_WAIT_SECONDS )) && RETRY_WAIT_SECONDS=$MIN_RETRY_WAIT_SECONDS

MAX_ATTEMPTS_UPPER_THRESHOLD=10
(( MAX_ATTEMPTS > MAX_ATTEMPTS_UPPER_THRESHOLD )) && MAX_ATTEMPTS=$MAX_ATTEMPTS_UPPER_THRESHOLD

# calls cleanup method on exit everytime
trap cleanup EXIT

deployment_application
if [[ $INPUT_WAIT_FOR_DEPLOYMENT ]];
then
  check_deployment_status
fi
