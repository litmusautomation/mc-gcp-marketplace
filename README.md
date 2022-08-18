# Manufacturing Connect installation guide

Manufacturing Connect is an integrated edge-to-cloud Industrial IoT platform that provides 
everything you need to put industrial data to work to enable smart manufacturing. 
The solution is purpose-built to collect, process and analyze data at the edge, 
then rapidly integrate the data with the Google Cloud Platform for analytics, AI and machine learning. 
This document is a guide to install the MC in Google Cloud Platform (GCP).
## Pre-installation tasks
### Enable GCP services
```sh
export GCP_PROJECT_ID='your-gcp-project-id'
gcloud services enable --project=${GCP_PROJECT_ID} container.googleapis.com
gcloud services enable --project=${GCP_PROJECT_ID} cloudiot.googleapis.com
```
### Create Pub/Sub topic for MDE integration (optional)
```sh
gcloud pubsub topics create input-messages --project=${GCP_PROJECT_ID}
```
### Create GKE cluster

The MC's services are deployed into a Kubernetes cluster. The cluster must be created before deploying the MC from the Google Cloud Marketplace.
*UBUNTU_CONTAINERD* is the only supported image type for GKE nodes 
```sh
export GKECLUSTER="mc-cluster"
export ZONE='us-central1-c'

gcloud beta container --project "${GCP_PROJECT_ID}" clusters create $GKECLUSTER --zone "${ZONE}" \
    --no-enable-basic-auth --release-channel "regular" --machine-type "e2-standard-2" --image-type "UBUNTU_CONTAINERD" \
    --disk-type "pd-standard" --disk-size "100" --metadata disable-legacy-endpoints=true \
    --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
    --max-pods-per-node "110" --num-nodes "3" --logging=SYSTEM,WORKLOAD --monitoring=SYSTEM \
    --enable-ip-alias  --no-enable-intra-node-visibility --default-max-pods-per-node "110" \
    --no-enable-master-authorized-networks --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver \
    --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 \
    --maintenance-window-start "2022-05-21T02:00:00Z" --maintenance-window-end "2022-05-22T02:00:00Z" \
    --maintenance-window-recurrence "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU" \
    --workload-pool "${GCP_PROJECT_ID}.svc.id.goog" --enable-shielded-nodes --node-locations "${ZONE}"
```

## Prepare GCP project

Follow this guide https://cloud.google.com/marketplace/docs/manage-billing#before_you_begin


## Deploy The Manufacturing Connect via Google Cloud Marketplace

### Purchase the Manufacturing Connect for a billing account

* A person with GCP Billing Admin role needs to open [the MC the Google Marketplace page](https://console.cloud.google.com/kubernetes/application(cameo:product/litmus-public/intelligent-manufacturing-connect))
* click *PURCHASE*
* click *MANAGE ACCOUNTS*
* link a service account that was created in the previous step

### Deploy the Manufacturing Connect to partcular GCP project

After you've created a Kubernetes cluster, you can [deploy the MC from the Google Cloud Marketplace](https://console.cloud.google.com/kubernetes/application(cameo:product/litmus-public/intelligent-manufacturing-connect)).  
Click *Configure* then follow the on-screen instructions. 
In dropdown list *Reporting service account* select the service account name

Once finished, review the post installation steps below.

## Post-installation tasks
### Change initial credentials (mandatory)

* Open [GKE applications list](https://console.cloud.google.com/kubernetes/application) in your GCP project 
* Click on the application which is just installed
* Click on *Show Info* Panel
* Follow instructions to get the application urls and initial credentials
* Change MC Admin password
* Change MC Keycloak Admin password
### Provision the MC instance with a license (mandatory)
* Get a license code using [the license request form](https://google-mc-licenses.litmus.io/)
* Open MC Admin Console
* Click License Server menu
* Follow instructions for *Offline Activation*
### Upload GCP credentials (optional)
* Open MC Admin Console
* Click Settings/Cloud Settings
* Follow instructions for *Generate Key* in the Cloud Credentials section
### Set GCS bucket (optional)
* Open MC Admin Console
* Click Settings/Cloud Settings
* Select Google Cloud Storage in Storage settings
* To create a bucket follow instructions for *Create bucket*
* Set bucket name
* Click Save

### Assotiate a domain name with MC Instance. Mandatory only if Google Authorization is needed for the MC instance
* assotiate MC external IP address with a domain name
* Open MC Admin Console
* Open Settings/Entrypoints
* Set the new domain name
* Click Save
### Setup Google Authentification (optional)
*a domain name must be associated with the MC instance*
#### OAuth consent screen

* Open APIs & Services OAuth consent screen https://console.cloud.google.com/apis/credentials/consent
* Select External type  
    In testing mode External allows add up to 100 google account from any organization  
    Internal type allows only users within the current organization  
* On the next screen set mandatory attributes  
    * App Name
    * User support email
    * Add authorized domain   
    Let’s say for MC we are going to use domain name *test.mc.domain.com* then we need to set *domain.com* as an authorized domain 
    * Developer contact information
#### Create OAuth 2.0 credentials
* Open APIs & Services OAuth credentials screen https://console.cloud.google.com/apis/credentials
* Create OAuth client ID  
Application type: Web application  
Authorized redirect url: `https://<your-domain>/auth/realms/standalone/broker/google/endpoint`
#### Setup MC Keycloak
* Open Keycloak Admin console
* Click Identity Providers
* Select *Google* from the list
* Set *Client ID* and *Secret ID* use values from the previous step
* Set First Login Flow to *google-login*
* Click Save
#### Grant permissions to google accounts
* Open MC Admin Console
* Click Users
* Add a new user (set google email)
* Enable the user
* Grant Admin role if required
