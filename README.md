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
          application_name: [YOUR_KAPSTAN_APPLICATION_NAME]
          image_tag: [YOUR_IMAGE_TAG_TO_DEPLOY]
          pre_deploy_image_tag: [YOUR_PRE_DEPLOY_IMAGE_TAG_TO_DEPLOY if any, otherwise omit]
          kapstan_api_key: [YOUR_KAPSTAN_WORKSPACE_API_KEY] # fetch from secrets
          wait_for_deployment: [true/false]
```

> There are three environment variables exposed as `KAPSTAN_DEPLOYMENT_ID`, `KAPSTAN_DEPLOYMENT_MESSAGE` and `KAPSTAN_DEPLOYMENT_STATUS`. Deployment action returns with exit(0) only when all steps are successful, otherwise it'll fail with exit(1).
> `KAPSTAN_DEPLOYMENT_STATUS` has value `STAGE_COMPLETED` when deployment is successful and would have other status based on error.

To create `YOUR_KAPSTAN_WORKSPACE_API_KEY`, navigate to the environments page and go to the settings of the environment for which you want to create the API Key. Click on create new API Key, and save the generate API Key. Wire it into the github secrets and use it here!