#!/bin/bash

set -e

GCP_PROJECT_ID=$1
ZONE=$2
GKECLUSTER=$3
NAMESPACE=$4
TARGET_VER=$5

gcloud container clusters get-credentials $GKECLUSTER --zone $ZONE --project $GCP_PROJECT_ID

APP=$(kubectl -n $NAMESPACE get application -o jsonpath='{range .items[*]}{@.metadata.name}')
SOURCE_VER=$(kubectl -n $NAMESPACE get application $APP -o jsonpath='{@.spec.descriptor.version}')

echo "updating $APP-activation"
IMAGE=$(kubectl -n $NAMESPACE get deployment/$APP-activation -o jsonpath='{@.spec.template.spec.containers[0].image}')
kubectl -n $NAMESPACE set image deployment/$APP-activation $APP-activation=${IMAGE/$SOURCE_VER/$TARGET_VER}

echo "updating $APP-admin"
IMAGE=$(kubectl -n $NAMESPACE get deployment/$APP-admin -o jsonpath='{@.spec.template.spec.containers[0].image}')
kubectl -n $NAMESPACE set image deployment/$APP-admin $APP-admin=${IMAGE/$SOURCE_VER/$TARGET_VER}

echo "updating $APP-alerts"
IMAGE=$(kubectl -n $NAMESPACE get deployment/$APP-alerts -o jsonpath='{@.spec.template.spec.containers[0].image}')
kubectl -n $NAMESPACE set image deployment/$APP-alerts $APP-alerts=${IMAGE/$SOURCE_VER/$TARGET_VER}

echo "updating $APP-api"
IMAGE=$(kubectl -n $NAMESPACE get deployment/$APP-api -o jsonpath='{@.spec.template.spec.containers[0].image}')
kubectl -n $NAMESPACE set image deployment/$APP-api $APP-api=${IMAGE/$SOURCE_VER/$TARGET_VER}

echo "updating $APP-cfg"
IMAGE=$(kubectl -n $NAMESPACE get deployment/$APP-cfg -o jsonpath='{@.spec.template.spec.containers[0].image}')
kubectl -n $NAMESPACE set image deployment/$APP-cfg $APP-cfg=${IMAGE/$SOURCE_VER/$TARGET_VER}

echo "updating $APP-clickhouse-sink"
IMAGE=$(kubectl -n $NAMESPACE get deployment/$APP-clickhouse-sink -o jsonpath='{@.spec.template.spec.containers[0].image}')
kubectl -n $NAMESPACE set image deployment/$APP-clickhouse-sink $APP-clickhouse-sink=${IMAGE/$SOURCE_VER/$TARGET_VER}

echo "updating $APP-emq-auth"
IMAGE=$(kubectl -n $NAMESPACE get deployment/$APP-emq-auth -o jsonpath='{@.spec.template.spec.containers[0].image}')
kubectl -n $NAMESPACE set image deployment/$APP-emq-auth $APP-emq-auth=${IMAGE/$SOURCE_VER/$TARGET_VER}

echo "updating $APP-events-sink"
IMAGE=$(kubectl -n $NAMESPACE get deployment/$APP-events-sink -o jsonpath='{@.spec.template.spec.containers[0].image}')
kubectl -n $NAMESPACE set image deployment/$APP-events-sink $APP-events-sink=${IMAGE/$SOURCE_VER/$TARGET_VER}

echo "updating $APP-jobs"
IMAGE=$(kubectl -n $NAMESPACE get deployment/$APP-jobs -o jsonpath='{@.spec.template.spec.containers[1].image}')
kubectl -n $NAMESPACE set image deployment/$APP-jobs $APP-jobs=${IMAGE/$SOURCE_VER/$TARGET_VER}

echo "updating $APP-keycloak"
IMAGE=$(kubectl -n $NAMESPACE get deployment/$APP-keycloak -o jsonpath='{@.spec.template.spec.containers[0].image}')
kubectl -n $NAMESPACE set image deployment/$APP-keycloak $APP-keycloak=${IMAGE/$SOURCE_VER/$TARGET_VER}

echo "updating $APP-lic"
IMAGE=$(kubectl -n $NAMESPACE get deployment/$APP-lic -o jsonpath='{@.spec.template.spec.containers[0].image}')
kubectl -n $NAMESPACE set image deployment/$APP-lic $APP-lic=${IMAGE/$SOURCE_VER/$TARGET_VER}

echo "updating $APP-mpcs-rbac"
IMAGE=$(kubectl -n $NAMESPACE get deployment/$APP-mpcs-rbac -o jsonpath='{@.spec.template.spec.containers[0].image}')
kubectl -n $NAMESPACE set image deployment/$APP-mpcs-rbac $APP-mpcs-rbac=${IMAGE/$SOURCE_VER/$TARGET_VER}

echo "updating $APP-mpcs"
IMAGE=$(kubectl -n $NAMESPACE get deployment/$APP-mpcs -o jsonpath='{@.spec.template.spec.containers[0].image}')
kubectl -n $NAMESPACE set image deployment/$APP-mpcs $APP-mpcs=${IMAGE/$SOURCE_VER/$TARGET_VER}

echo "updating $APP-mqtt-bind"
IMAGE=$(kubectl -n $NAMESPACE get deployment/$APP-mqtt-bind -o jsonpath='{@.spec.template.spec.containers[0].image}')
kubectl -n $NAMESPACE set image deployment/$APP-mqtt-bind $APP-mqtt-bind=${IMAGE/$SOURCE_VER/$TARGET_VER}

echo "updating $APP-nginx"
IMAGE=$(kubectl -n $NAMESPACE get deployment/$APP-nginx -o jsonpath='{@.spec.template.spec.containers[0].image}')
kubectl -n $NAMESPACE set image deployment/$APP-nginx nginx=${IMAGE/$SOURCE_VER/$TARGET_VER}

echo "updating $APP-remote"
IMAGE=$(kubectl -n $NAMESPACE get deployment/$APP-remote -o jsonpath='{@.spec.template.spec.containers[0].image}')
kubectl -n $NAMESPACE set image deployment/$APP-remote $APP-remote=${IMAGE/$SOURCE_VER/$TARGET_VER}

echo "updating $APP version"
PATCH_APP="{\"spec\": {\"descriptor\": {\"version\": \"$TARGET_VER\"}}}"
kubectl -n $NAMESPACE patch application $APP -p "$PATCH_APP" --type=merge

kubectl -n $NAMESPACE set env deployment/$APP-remote \
  CONFIG_SERVER_URL="http://$APP-cfg.$NAMESPACE.svc.cluster.local:8888" \
  --overwrite=false

kubectl -n $NAMESPACE get deployment/$APP-remote -o jsonpath="{.spec.template.spec.containers[0].env[?(@.name=='LEM_CFG_AUTH_TOKEN')]}" | grep -q 'LEM_CFG_AUTH_TOKEN' || kubectl  -n $NAMESPACE patch deployment/$APP-remote --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/env/-",
    "value": {
      "name": "LEM_CFG_AUTH_TOKEN",
      "valueFrom": {
        "secretKeyRef": {
          "name": "'"$APP"'-cfg-auth",
          "key": "cfg-auth-token",
          "optional": false
        }
      }
    }
  }
]'
