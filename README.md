# deployment-action

GitHub Action for triggering Application Deployment

```
on: [push]
jobs:
  deploy:
    runs-on: ubuntu-latest
    name: Deploy on Kapstan
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Deploy on Kapstan
        id: kapstan
        uses: kapstan-io/deployment-action@v0.3
        with:
          organization_id: [YOUR_KAPSTAN_ORGANIZATION_ID]
          environment_id: [YOUR_KAPSTAN_ENVIRONMENT_ID]
          application_id: [YOUR_KAPSTAN_APPLICATION_ID]
          image_tag: [YOUR_IMAGE_TAG_TO_DEPLOY]
          image_repository_name: [YOUR_KAPSTAN_IAMGE_REPOSITORY_NAME]
          kapstan_api_key: [YOUR_KAPSTAN_WORKSPACE_API_KEY] # fetch from secrets
          wait_for_deployment: [true/false]
```

> Access deployment ID and deployment message within your workflow using `KAPSTAN_DEPLOYMENT_ID` and `KAPSTAN_DEPLOYMENT_MESSAGE` enviroment variable set int `$GITHUB_ENV`
