# UDP responder hosted on GCE+Kubernetes

© Evin Callahan

# Quickstart

To get up and running quickly with this service, run the following:

```
$ docker run -it --rm -v $(pwd)/app:/usr/src/app -p 1234:1234/udp gaieges/sreeval
```

# Building locally

```bash
$ docker build -t gaieges/sreeval app
```

# Using the service

```bash
$ echo -n  '[17/06/2016 12:30] Fun message here' | nc -u 127.0.0.1 1234
```


# Deploying to GCE via Terraform

## Prereq's

- Ensure you have terraform installed: `brew install terraform`
- Ensure you have a Google cloud account set up
- Install the `gcloud` cli tool: `brew cask install google-cloud-sdk`
- Run: `gcloud init` if you haven't already
- Get an application service account [here](https://console.cloud.google.com/apis/credentials/serviceaccountkey), and save the resultant file to disk somewhere
- Set Gcloud environment variables:
    - `$ export GOOGLE_APPLICATION_CREDENTIALS="[PATH_TO_SERVICE_ACCOUNT_JSON]"`
    - `$ export GOOGLE_PROJECT="[MY_PROJECT]"`
- Ensure the account / project in question has the proper privileges:
    - https://console.developers.google.com/apis/library/container.googleapis.com/?project=[MY_PROJECT]
    - https://console.developers.google.com/apis/api/compute.googleapis.com/?project=[MY_PROJECT]
- Finally for monitoring, you'll need a datadog account, and keys obtained from this location: https://app.datadoghq.com/account/settings#api
    - Get an "app key" and an "api key", you'll use this later


## Deploying

Simply use terraform to do all the work:

```
cd terraform
terraform init
terraform apply -auto-approve \
  -var k8s_username=[USERNAME] \
  -var k8s_password=[PASSWORD] \
  -var datadog_api_key=[YOUR_DATADOG_API_KEY] \
  -var datadog_app_key=[YOUR_DATADOG_APP_KEY] \
  -var alert_email=[EMAIL_ADDRESS_FOR_ALERTS]
```

## Other fun stuff

- Use `kubectl` with deployed k8s cluster: `gcloud container clusters get-credentials sreeval-ec-k8s-cluster --zone us-east1-b`
    - Change args if you end up changing names / zones


# Notes

- Had fun messing with some stuff I don't usually use: k8s, GCE, Terraform
- This eval does not take 2-3 hours.. but rather a fair amount longer, especially if you're not super familiar what can and can't load balance UDP (my biggest mistake/time sink was trying out fargate before realizing that it cant do the sort of balancing needed)
- Some tweaks here are definitely needed, could make things a little more variable:
    - The datadog alert criteria
- Use datadog via replicaset, not a service
- Use stackdriver to do monitoring on k8s, not datadog
- Separate k8s spec files from terraform, not great to tie app deployments to infrastructure provisioning
- Break up the tf files a bit more into variables, outputs, and different functions
