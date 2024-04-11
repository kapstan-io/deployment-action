#!/bin/bash
set -e

kapstan_deployment_trigger_url="https://api.kapstan.io/external/organizations/${INPUT_ORGANIZATION_ID}/workspaces/$INPUT_ENVIRONMENT_ID/applications/${INPUT_APPLICATION_ID}/deploy"
echo "Prepared-url: $kapstan_deployment_trigger_url"

request_body=$(cat <<EOF
{ 
  "imageTag": "$INPUT_IMAGE_TAG",
  "imageRepositoryName": "$INPUT_IMAGE_REPOSITORY_NAME",
  "comment": "Reason: Trigger by action ${GITHUB_EVENT_NAME} on ${GITHUB_REF_NAME} in ${GITHUB_REPOSITORY}"
}
EOF
)

echo "Request_body: $request_body"

echo "Making API call to Kapstan"
status_code=$(curl -sS -k -o /dev/null -w "%{http_code}" -X POST "$kapstan_deployment_trigger_url" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $INPUT_KAPSTAN_API_KEY" \
  -d "$request_body")

echo "Got response from Kapstan: $status_code"
