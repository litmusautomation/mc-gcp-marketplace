# Manufacturing Connect installation guide

Manufacturing Connect is an integrated edge-to-cloud Industrial IoT platform that provides 
everything you need to put industrial data to work to enable smart manufacturing. 
The solution is purpose-built to collect, process and analyze data at the edge, 
then rapidly integrate the data with the Google Cloud Platform for analytics, AI and machine learning. 
This document is a guide to install the MC in Google Cloud Platform (GCP).

## Pre-installation tasks

### Define environment variables
```sh
export GCP_PROJECT_ID='your-gcp-project-id'
export REGION='us-central1'
export ZONE='us-central1-c'
export NETWORK_NAME="sfp-private-network"
export SUBNET_NAME="sfp-subnet"
export GKECLUSTER="mc-cluster"
```

MDE network/subnet names were changed since MDE 1.3.0. If Manufacturing Connect is deploying or will be deployed with MDE 1.3.0 in one GCP project, please update these environment variables accordingly.

```sh
export NETWORK_NAME=mde-private-network
export SUBNET_NAME="mde-subnet"
```

### Enable GCP services
```sh
gcloud services enable --project=${GCP_PROJECT_ID} container.googleapis.com
```

### Create a network If MDE is not installed

```sh
gcloud compute networks create "$NETWORK_NAME" --project="$GCP_PROJECT_ID" \
  --description="MDE private network" \
  --subnet-mode=custom \
  --mtu=1460 \
  --bgp-routing-mode=regional
gcloud compute networks subnets create "$SUBNET_NAME" --project="$GCP_PROJECT_ID" \
  --range=10.154.0.0/20 \
  --network="$NETWORK_NAME" \
  --region="$REGION" \
  --enable-private-ip-google-access
```
### Create GKE cluster

The MC's services are deployed into a Kubernetes cluster. The cluster must be created before deploying the MC from the Google Cloud Marketplace.
*UBUNTU_CONTAINERD* is the only supported image type for GKE nodes 
The MC can be deployed on public or private GKE cluster

#### Deployment on public GKE cluster
```sh
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
    --workload-pool "${GCP_PROJECT_ID}.svc.id.goog" --enable-shielded-nodes --node-locations "${ZONE}" \
    --network "${NETWORK_NAME}" --subnetwork "${SUBNET_NAME}" --labels "goog-packaged-solution=mfg-mde"
```

#### Deployment on private GKE cluster

```sh
gcloud beta container clusters create $GKECLUSTER --project "$GCP_PROJECT_ID" --zone "$ZONE" \
            --no-enable-basic-auth --release-channel "regular" --machine-type "e2-standard-2" --image-type "UBUNTU_CONTAINERD" \
            --disk-type "pd-standard" --disk-size "100" --metadata disable-legacy-endpoints=true \
            --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
            --max-pods-per-node "110" --num-nodes "3" --logging=SYSTEM,WORKLOAD --monitoring=SYSTEM \
            --enable-ip-alias  --no-enable-intra-node-visibility --default-max-pods-per-node "110" \
            --enable-master-authorized-networks --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver \
            --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 \
            --maintenance-window-start "2022-11-21T02:00:00Z" --maintenance-window-end "2022-11-22T02:00:00Z" \
            --maintenance-window-recurrence "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU" \
            --workload-pool "$GCP_PROJECT_ID.svc.id.goog" --enable-shielded-nodes --node-locations "$ZONE" \
            --network "$NETWORK_NAME" --subnetwork "$SUBNET_NAME" --labels "goog-packaged-solution=mfg-mde" \
            --enable-private-nodes --enable-private-endpoint --master-ipv4-cidr 10.155.1.0/28
```

Kubernetes control nodes CIDR `--master-ipv4-cidr 10.155.1.0/28` here is just an example. It can be modified according to a customer's network setup   

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
In dropdown list *Reporting service account* select the service account name.  
If the MC is deployed on private GKE cluster select Internal Load Balancer option.

Once finished, review the post installation steps below.

## Post-installation tasks
### Change initial credentials (mandatory)

* Open [GKE applications list](https://console.cloud.google.com/kubernetes/application) in your GCP project 
* Click on the application which is just installed
* Click on *Show Info* Panel
* Follow instructions to get the application urls and initial credentials
* Change MC Admin password
* Change MC Keycloak Admin password

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

## Upgrading Manufactring Connect

Prepare values to run upgrade script

* GCP project id
* Zone where GKE cluster is deployed
* GKE cluster name
* Kebernetes namespace where Manufacturing Connect is deployed

### Clone git repository

```
git clone https://github.com/litmusautomation/mc-gcp-marketplace.git
```

### Run upgrade script

TARGET_VERSION is required MC target version, for example `2.8.0-120`

```
cd mc-gcp-marketplace
./upgrade-mc.sh 'GCP_PROJECT_ID' 'ZONE' 'GKECLUSTER' 'NAMESPACE' 'TARGET_VERSION'
```
