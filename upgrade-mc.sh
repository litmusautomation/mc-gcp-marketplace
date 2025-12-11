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

echo "updating $APP-cfg"
IMAGE=$(kubectl -n $NAMESPACE get deployment/$APP-cfg -o jsonpath='{@.spec.template.spec.containers[0].image}')
if [[ "$(printf '%s\n' "$SOURCE_VER" "2.31.0" | sort -V | head -n1)" != "2.31.0" && "$(printf '%s\n' "$TARGET_VER" "2.31.0" | sort -V | head -n1)" == "2.31.0" ]]; then
  kubectl -n $NAMESPACE set image statefulset/$APP-hazelcast $APP-hazelcast=gcr.io/litmus-public/mc-addons/hazelcast:5.3.1
  kubectl -n $NAMESPACE set env deployment/$APP-nginx LEM_MPCS_RBAC_ADDR="${APP}-mpcs-rbac.${NAMESPACE}.svc.cluster.local:8084"
  kubectl -n $NAMESPACE set env deployment/$APP-cfg KEYCLOAK_URL="http://${APP}-keycloak.${NAMESPACE}.svc.cluster.local/auth"
  kubectl -n $NAMESPACE set env deployment/$APP-cfg KEYCLOAK_AUTH_SERVER_URL="http://${APP}-keycloak.${NAMESPACE}.svc.cluster.local/auth"
fi
kubectl -n $NAMESPACE set image deployment/$APP-cfg $APP-cfg=${IMAGE/$SOURCE_VER/$TARGET_VER}

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

if [[ "$(printf '%s\n' "$SOURCE_VER" "2.31.0" | sort -V | head -n1)" != "2.31.0" && "$(printf '%s\n' "$TARGET_VER" "2.31.0" | sort -V | head -n1)" == "2.31.0" ]]; then
kubectl -n $NAMESPACE --ignore-not-found=true delete statefulsets $APP-clickhouse 
kubectl -n $NAMESPACE --ignore-not-found=true delete statefulsets $APP-clickhouse-replica
kubectl -n $NAMESPACE --ignore-not-found=true delete service $APP-clickhouse
kubectl -n $NAMESPACE --ignore-not-found=true delete service $APP-clickhouse-replica
kubectl -n $NAMESPACE --ignore-not-found=true delete service $APP-clickhouse-headless
kubectl -n $NAMESPACE --ignore-not-found=true delete configmap secret $APP-clickhouse-config
kubectl -n $NAMESPACE --ignore-not-found=true delete configmap secret $APP-clickhouse-metrica
kubectl -n $NAMESPACE --ignore-not-found=true delete configmap secret $APP-clickhouse-users

cat <<EOF | kubectl -n $NAMESPACE apply -f -
---
apiVersion: v1
kind: Service
metadata:
  name: $APP-clickhouse-headless
  namespace: $NAMESPACE
  labels:
    app.kubernetes.io/component: clickhouse
spec:
  clusterIP: None
  selector:
    app.kubernetes.io/component: clickhouse
  ports:
    - name: http
      port: 8123
      targetPort: 8123
    - name: native
      port: 9000
      targetPort: 9000
    - name: interserver
      port: 9009
      targetPort: 9009

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${APP}-clickhouse-config
  namespace: $NAMESPACE
data:
  01-listen.xml: |
    <clickhouse>
      <listen_host>0.0.0.0</listen_host>
      <listen_try>1</listen_try>
      <logger>
        <level>information</level>
        <log>/var/log/clickhouse-server/clickhouse-server.log</log>
        <errorlog>/var/log/clickhouse-server/clickhouse-server.err.log</errorlog>
      </logger>
      <http_port>8123</http_port>
      <tcp_port>9000</tcp_port>
      <interserver_http_port>9009</interserver_http_port>
      <max_concurrent_queries>150</max_concurrent_queries>
      <max_server_memory_usage>0</max_server_memory_usage> <!-- rely on cgroup -->
    </clickhouse>
  02-users.xml: |
    <clickhouse>
      <profiles>
        <default>
          <max_memory_usage>0</max_memory_usage> <!-- rely on cgroup -->
          <use_uncompressed_cache>0</use_uncompressed_cache>
        </default>
      </profiles>
      <users>
        <default>
          <password></password>
          <networks>
            <ip>::/0</ip>
          </networks>
          <quota>default</quota>
          <profile>default</profile>
        </default>
      </users>
      <quotas>
        <default>
          <interval>
            <duration>3600</duration>
            <queries>0</queries>
            <errors>0</errors>
            <result_rows>0</result_rows>
            <read_rows>0</read_rows>
            <execution_time>0</execution_time>
          </interval>
        </default>
      </quotas>
    </clickhouse>

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ${APP}-clickhouse
  namespace: $NAMESPACE
spec:
  serviceName: clickhouse
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/component: clickhouse
  template:
    metadata:
      labels:
        app.kubernetes.io/component: clickhouse
    spec:
      terminationGracePeriodSeconds: 120
      securityContext:
        fsGroup: 101    # clickhouse user gid inside container
        runAsUser: 101  # clickhouse user uid
        runAsGroup: 101
        runAsNonRoot: true
      containers:
        - name: clickhouse
          image: gcr.io/litmus-public/mc-addons/clickhouse-server:23.10.4
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 8123
            - name: native
              containerPort: 9000
            - name: interserver
              containerPort: 9009
          env:
            # Tune for your workload; CH respects cgroup limits when unset or 0 in config.
            - name: CLICKHOUSE_DB
              value: default
          volumeMounts:
            - name: data
              mountPath: /var/lib/clickhouse
            - name: config
              mountPath: /etc/clickhouse-server/config.d
            - name: users
              mountPath: /etc/clickhouse-server/users.d
            - name: logs
              mountPath: /var/log/clickhouse-server
          readinessProbe:
            httpGet:
              path: /ping
              port: 8123
            initialDelaySeconds: 10
            periodSeconds: 5
            timeoutSeconds: 2
            failureThreshold: 12
          livenessProbe:
            httpGet:
              path: /ping
              port: 8123
            initialDelaySeconds: 20
            periodSeconds: 10
            timeoutSeconds: 2
            failureThreshold: 6
          resources:
            requests:
              cpu: "0.3"
              memory: "1Gi"
              ephemeral-storage: "1Gi"
            limits:
              cpu: "0.5"
              memory: "2Gi"
              ephemeral-storage: "4Gi"
          lifecycle:
            preStop:
              exec:
                command: ["/bin/sh","-c","kill -TERM 1; for i in \$(seq 1 120); do if ! kill -0 1 2>/dev/null; then exit 0; fi; sleep 1; done; exit 1"]
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                topologyKey: kubernetes.io/hostname
                labelSelector:
                  matchLabels:
                    app.kubernetes.io/component: clickhouse
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              app.kubernetes.io/component: clickhouse
      volumes:
        - name: config
          configMap:
            name: ${APP}-clickhouse-config
            items:
              - key: 01-listen.xml
                path: 01-listen.xml
        - name: users
          configMap:
            name: ${APP}-clickhouse-config
            items:
              - key: 02-users.xml
                path: 02-users.xml
        - name: logs
          emptyDir: {}
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 20Gi
---
apiVersion: v1
kind: Service
metadata:
  name: ${APP}-clickhouse
  namespace: $NAMESPACE
  labels:
    app.kubernetes.io/component: clickhouse
spec:
  type: ClusterIP
  selector:
    app.kubernetes.io/component: clickhouse
  ports:
    - name: http
      port: 8123
      targetPort: 8123
    - name: native
      port: 9000
      targetPort: 9000

---

apiVersion: v1
kind: Service
metadata:
  name: ${APP}-mpcs-rbac
  namespace: $NAMESPACE
spec:
  selector:
    app.kubernetes.io/name: "${APP}"
    app.kubernetes.io/component: "lem-mpcs-rbac"
  ports:
    - protocol: TCP
      port: 9086
      targetPort: 9086
      name: "rbac-grpc-api"
    - protocol: TCP
      port: 8084
      targetPort: 8084
      name: "rbac-http"

EOF

fi
    