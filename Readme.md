```
export CLUSTER_MASTER=192.168.3.100
export CLUSTER_DEPLOY_USER=slavko
k3sup install --ip $CLUSTER_MASTER --user $CLUSTER_DEPLOY_USER --k3s-extra-args '--no-deploy traefik'
```

result of the execution will be kind of

```
ssh: sudo cat /etc/rancher/k3s/k3s.yaml

apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJWekNCL3FBREFnRUNBZ0VBTUFvR0NDcUdTTTQ5QkFNQ01DTXhJVEFmQmdOVkJBTU1HR3N6Y3kxelpYSjIKWlhJdFkyRkFNVFU0TnpNd056WTRNekFlRncweU1EQTBNVGt4TkRRNE1ETmFGdzB6TURBME1UY3hORFE0TUROYQpNQ014SVRBZkJnTlZCQU1NR0dzemN5MXpaWEoyWlhJdFkyRkFNVFU0TnpNd056WTRNekJaTUJNR0J5cUdTTTQ5CkFnRUdDQ3FHU000OUF3RUhBMElBQlBOQ2ZHODFDVVBpRW9SN3RWWENvYjJqWUFiV2xyNnN4eEpDRDRLWEFaZXIKTmtqZUlVR3YrZStNRXdLcndBUi9ZRHJwSHh6WW52QWNhMlVZUXZTYlpTV2pJekFoTUE0R0ExVWREd0VCL3dRRQpBd0lDcERBUEJnTlZIUk1CQWY4RUJUQURBUUgvTUFvR0NDcUdTTTQ5QkFNQ0EwZ0FNRVVDSVFDSHkydlpBeWROClpvc1NFdTJwanlCOTNmSHdvOVJIenlHREFjUnpad3dZRUFJZ05wU0JtY0RabGNmek5hV1dEUi9nK0RmSVBhMU4KcTVXVjRrM0JWeUZzbXdVPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    server: https://127.0.0.1:6443
  name: default
contexts:
- context:
    cluster: default
    user: default
  name: default
current-context: default
kind: Config
preferences: {}
users:
- name: default
  user:
    password: 8ab6385ebb3abb27646590238b52e643
    username: admin
Result: apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJWekNCL3FBREFnRUNBZ0VBTUFvR0NDcUdTTTQ5QkFNQ01DTXhJVEFmQmdOVkJBTU1HR3N6Y3kxelpYSjIKWlhJdFkyRkFNVFU0TnpNd056WTRNekFlRncweU1EQTBNVGt4TkRRNE1ETmFGdzB6TURBME1UY3hORFE0TUROYQpNQ014SVRBZkJnTlZCQU1NR0dzemN5MXpaWEoyWlhJdFkyRkFNVFU0TnpNd056WTRNekJaTUJNR0J5cUdTTTQ5CkFnRUdDQ3FHU000OUF3RUhBMElBQlBOQ2ZHODFDVVBpRW9SN3RWWENvYjJqWUFiV2xyNnN4eEpDRDRLWEFaZXIKTmtqZUlVR3YrZStNRXdLcndBUi9ZRHJwSHh6WW52QWNhMlVZUXZTYlpTV2pJekFoTUE0R0ExVWREd0VCL3dRRQpBd0lDcERBUEJnTlZIUk1CQWY4RUJUQURBUUgvTUFvR0NDcUdTTTQ5QkFNQ0EwZ0FNRVVDSVFDSHkydlpBeWROClpvc1NFdTJwanlCOTNmSHdvOVJIenlHREFjUnpad3dZRUFJZ05wU0JtY0RabGNmek5hV1dEUi9nK0RmSVBhMU4KcTVXVjRrM0JWeUZzbXdVPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    server: https://127.0.0.1:6443
  name: default
contexts:
- context:
    cluster: default
    user: default
  name: default
current-context: default
kind: Config
preferences: {}
users:
- name: default
  user:
    password: 8ab6385ebb3abb27646590238b52e643
    username: admin
 
Saving file to: /home/slavko/kubeconfig

# Test your cluster with:
export KUBECONFIG=/home/slavko/kubeconfig
kubectl get node -o wide
```


# k3s magic reveal

Generally k3s has no magic, and can be presented even in form of docker-compose file, as per https://docs.traefik.io/v2.0/user-guides/crd-acme/


```
server:
  image: rancher/k3s:v0.8.0
  command: server --disable-agent --no-deploy traefik
  environment:
    - K3S_CLUSTER_SECRET=somethingtotallyrandom
    - K3S_KUBECONFIG_OUTPUT=/output/kubeconfig.yaml
    - K3S_KUBECONFIG_MODE=666
  volumes:
    # k3s will generate a kubeconfig.yaml in this directory. This volume is mounted
    # on your host, so you can then 'export KUBECONFIG=/somewhere/on/your/host/out/kubeconfig.yaml',
    # in order for your kubectl commands to work.
    - /somewhere/on/your/host/out:/output
    # This directory is where you put all the (yaml) configuration files of
    # the Kubernetes resources.
    - /somewhere/on/your/host/in:/var/lib/rancher/k3s/server/manifests
  ports:
    - 6443:6443

node:
  image: rancher/k3s:v0.8.0
  privileged: true
  links:
    - server
  environment:
    - K3S_URL=https://server:6443
    - K3S_CLUSTER_SECRET=somethingtotallyrandom
  volumes:
    # this is where you would place a alternative traefik image (saved as a .tar file with
    # 'docker save'), if you want to use it, instead of the traefik:v2.0 image.
    - /sowewhere/on/your/host/custom-image:/var/lib/rancher/k3s/agent/images
```

traefik introduces it's own resources

```
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: ingressroutes.traefik.containo.us

spec:
  group: traefik.containo.us
  version: v1alpha1
  names:
    kind: IngressRoute
    plural: ingressroutes
    singular: ingressroute
  scope: Namespaced

---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: ingressroutetcps.traefik.containo.us

spec:
  group: traefik.containo.us
  version: v1alpha1
  names:
    kind: IngressRouteTCP
    plural: ingressroutetcps
    singular: ingressroutetcp
  scope: Namespaced

---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: middlewares.traefik.containo.us

spec:
  group: traefik.containo.us
  version: v1alpha1
  names:
    kind: Middleware
    plural: middlewares
    singular: middleware
  scope: Namespaced

---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: tlsoptions.traefik.containo.us

spec:
  group: traefik.containo.us
  version: v1alpha1
  names:
    kind: TLSOption
    plural: tlsoptions
    singular: tlsoption
  scope: Namespaced

---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: traefik-ingress-controller

rules:
  - apiGroups:
      - ""
    resources:
      - services
      - endpoints
      - secrets
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
    resources:
      - ingresses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
    resources:
      - ingresses/status
    verbs:
      - update
  - apiGroups:
      - traefik.containo.us
    resources:
      - middlewares
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - traefik.containo.us
    resources:
      - ingressroutes
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - traefik.containo.us
    resources:
      - ingressroutetcps
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - traefik.containo.us
    resources:
      - tlsoptions
    verbs:
      - get
      - list
      - watch

---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: traefik-ingress-controller

roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: traefik-ingress-controller
subjects:
  - kind: ServiceAccount
    name: traefik-ingress-controller
    namespace: default
```

# Pointing traefik to k3s cluster


When deployed into Kubernetes, Traefik will read the environment variables KUBERNETES_SERVICE_HOST and KUBERNETES_SERVICE_PORT or KUBECONFIG to construct the endpoint.

The access token will be looked up in /var/run/secrets/kubernetes.io/serviceaccount/token and the SSL CA certificate in /var/run/secrets/kubernetes.io/serviceaccount/ca.crt. Both are provided mounted automatically when deployed inside Kubernetes.

The endpoint may be specified to override the environment variable values inside a cluster.

When the environment variables are not found, Traefik will try to connect to the Kubernetes API server with an external-cluster client. In this case, the endpoint is required. Specifically, it may be set to the URL used by kubectl proxy to connect to a Kubernetes cluster using the granted authentication and authorization of the associated kubeconfig.


```toml
[providers.kubernetesCRD]
  endpoint = "http://localhost:8080"
  token = "mytoken"
```

```yaml
providers:
  kubernetesCRD:
    endpoint = "http://localhost:8080"
    token = "mytoken"
    # ...
```

```sh
--providers.kubernetescrd.endpoint=http://localhost:8080
--providers.kubernetescrd.token=mytoken
```

On a first run, if you have traefik outside, most likely you will not have access tokens for `traefik-ingress-controller`

To create one:

A controller loop ensures a secret with an API token exists for each service account. To create additional API tokens for a service account, create a secret of type ServiceAccountToken with an annotation referencing the service account, and the controller will update it with a generated token:

```
{
    "kind": "Secret",
    "apiVersion": "v1",
    "metadata": {
        "name": "traefik-manual-token",
        "annotations": {
            "kubernetes.io/service-account.name": "traefik-ingress-controller"
        }
    },
    "type": "kubernetes.io/service-account-token"
}
```

to create

```sh
kubectl create -f ./traefik-secret.json
kubectl describe secret traefik-manual-token
```

to delete/invalidate

```
kubectl delete secret traefik-manual-token
```


Discovering access token

```sh
# Check all possible clusters, as your .KUBECONFIG may have multiple contexts:
kubectl config view -o jsonpath='{"Cluster name\tServer\n"}{range .clusters[*]}{.name}{"\t"}{.cluster.server}{"\n"}{end}'

# Output kind of
# Alias tip: k config view -o jsonpath='{"Cluster name\tServer\n"}{range .clusters[*]}{.name}{"\t"}{.cluster.server}{"\n"}{end}'
# Cluster name	Server
# default	https://127.0.0.1:6443

# You are interested in: "default", if you did not name it differently

# Select name of cluster you want to interact with from above output:
export CLUSTER_NAME="default"

# Point to the API server referring the cluster name
export APISERVER=$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"$CLUSTER_NAME\")].cluster.server}")
# usually https://127.0.0.1:6443

# Gets the token value
export TOKEN=$(kubectl get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='traefik-ingress-controller')].data.token}" --namespace kube-system|base64 --decode)

# Explore the API with TOKEN
curl -X GET $APISERVER/api --header "Authorization: Bearer $TOKEN" --insecure
```

If ok, you should receive successful response, kind of

```
All keys already loaded
{
  "kind": "APIVersions",
  "versions": [
    "v1"
  ],
  "serverAddressByClientCIDRs": [
    {
      "clientCIDR": "0.0.0.0/0",
      "serverAddress": "192.168.3.100:6443"
    }
  ]

```

and some facts, like token

```
eyJhbGciOiJSUzI1NiIsImtpZCI6IjBUeTQyNm5nakVWbW5PaTRRbDhucGlPeWhlTHhxTXZjUDJsRmNacURjVnMifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJ0cmFlZmlrLWluZ3Jlc3MtY29udHJvbGxlci10b2tlbi12emM3diIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJ0cmFlZmlrLWluZ3Jlc3MtY29udHJvbGxlciIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6ImQ5NTc3ZTkxLTdlNjQtNGMwNi1iZDgyLWNkZTk0OWM4MTI1MSIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlLXN5c3RlbTp0cmFlZmlrLWluZ3Jlc3MtY29udHJvbGxlciJ9.Mk8EBS4soO8uX-uSnV3o4qZKR6Iw6bgeSmPhHbJ2fjuqFgLnLh4ggxa-N9AqmCsEWiYjSi5oKAu986UEC-_kGQh3xaCYsUwlkM8147fsnwCbomSeGIct14JztVL9F8JwoDH6T0BOEjn-J9uY8-fUKYL_Y7uTrilhFapuILPsj_bFfgIeOOapRD0XshKBQV9Qzg8URxyQyfzl68ilm1Q13h3jLj8CFE2RlgEUFk8TqYH4T4fhfpvV-gNdmKJGODsJDI1hOuWUtBaH_ce9w6woC9K88O3FLKVi7fbvlDFrFoJ2iVZbrRALPjoFN92VA7a6R3pXUbKebTI3aUJiXyfXRQ
```

external address of the api server  `https://192.168.3.100:6443` as per last response

Again, nothing magic in token: you can use https://jwt.io/#debugger-io to inspect it's contents

```
{
  "alg": "RS256",
  "kid": "0Ty426ngjEVmnOi4Ql8npiOyheLxqMvcP2lFcZqDcVs"
}
{
  "iss": "kubernetes/serviceaccount",
  "kubernetes.io/serviceaccount/namespace": "kube-system",
  "kubernetes.io/serviceaccount/secret.name": "traefik-ingress-controller-token-vzc7v",
  "kubernetes.io/serviceaccount/service-account.name": "traefik-ingress-controller",
  "kubernetes.io/serviceaccount/service-account.uid": "d9577e91-7e64-4c06-bd82-cde949c81251",
  "sub": "system:serviceaccount:kube-system:traefik-ingress-controller"
}
```

```
export APISERVER=https://192.168.3.100:6443
export TOKEN=$(cat kubernetes_data/token)

curl -X GET $APISERVER/api --header "Authorization: Bearer $TOKEN" --insecure

curl -X GET $APISERVER/api/v1/endpoints --header "Authorization: Bearer $TOKEN" --insecure
```


# Troubleshouting

Consider some of  https://github.com/Voronenko/dotfiles/blob/master/Makefile#L185

Like

UI: Octant


Inspect credentials for system account

```
rakkess --sa kube-system:traefik-ingress-controller

```

Reverse task: check which roles are associated with service account

```
kubectl get clusterrolebindings -o json | jq -r '
  .items[] |
  select(
    .subjects // [] | .[] |
    [.kind,.namespace,.name] == ["ServiceAccount","kube-system","traefik-ingress-controller"]
  ) |
  .metadata.name'
```

## traefik switches

```
    --providers.kubernetescrd  (Default: "false")
        Enable Kubernetes backend with default settings.
    --providers.kubernetescrd.certauthfilepath  (Default: "")
        Kubernetes certificate authority file path (not needed for in-cluster client).
    --providers.kubernetescrd.disablepasshostheaders  (Default: "false")
        Kubernetes disable PassHost Headers.
    --providers.kubernetescrd.endpoint  (Default: "")
        Kubernetes server endpoint (required for external cluster client).
    --providers.kubernetescrd.ingressclass  (Default: "")
        Value of kubernetes.io/ingress.class annotation to watch for.
    --providers.kubernetescrd.labelselector  (Default: "")
        Kubernetes label selector to use.
    --providers.kubernetescrd.namespaces  (Default: "")
        Kubernetes namespaces.
    --providers.kubernetescrd.throttleduration  (Default: "0")
        Ingress refresh throttle duration
    --providers.kubernetescrd.token  (Default: "")
        Kubernetes bearer token (not needed for in-cluster client).
    --providers.kubernetesingress  (Default: "false")
        Enable Kubernetes backend with default settings.
    --providers.kubernetesingress.certauthfilepath  (Default: "")
        Kubernetes certificate authority file path (not needed for in-cluster client).
    --providers.kubernetesingress.disablepasshostheaders  (Default: "false")
        Kubernetes disable PassHost Headers.
    --providers.kubernetesingress.endpoint  (Default: "")
        Kubernetes server endpoint (required for external cluster client).
    --providers.kubernetesingress.ingressclass  (Default: "")
        Value of kubernetes.io/ingress.class annotation to watch for.
    --providers.kubernetesingress.ingressendpoint.hostname  (Default: "")
        Hostname used for Kubernetes Ingress endpoints.
    --providers.kubernetesingress.ingressendpoint.ip  (Default: "")
        IP used for Kubernetes Ingress endpoints.
    --providers.kubernetesingress.ingressendpoint.publishedservice  (Default: "")
        Published Kubernetes Service to copy status from.
    --providers.kubernetesingress.labelselector  (Default: "")
        Kubernetes Ingress label selector to use.
    --providers.kubernetesingress.namespaces  (Default: "")
        Kubernetes namespaces.
    --providers.kubernetesingress.throttleduration  (Default: "0")
        Ingress refresh throttle duration
    --providers.kubernetesingress.token  (Default: "")
        Kubernetes bearer token (not needed for in-cluster client).
```


If you are keen which information is queried by traefik:

```
traefik_1    | E0421 12:30:12.624877       1 reflector.go:125] pkg/mod/k8s.io/client-go@v0.0.0-20190718183610-8e956561bbf5/tools/cache/reflector.go:98: Failed to list *v1.Endpoints: Get https://192.168.3.101:6443/api/v1/endpoints?limit=500&resourceVersion=0: dial tcp 192.168.3.101:6443: connect: no route to host
traefik_1    | E0421 12:30:12.625341       1 reflector.go:125] pkg/mod/k8s.io/client-go@v0.0.0-20190718183610-8e956561bbf5/tools/cache/reflector.go:98: Failed to list *v1.Service: Get https://192.168.3.101:6443/api/v1/services?limit=500&resourceVersion=0: dial tcp 192.168.3.101:6443: connect: no route to host
traefik_1    | E0421 12:30:12.625395       1 reflector.go:125] pkg/mod/k8s.io/client-go@v0.0.0-20190718183610-8e956561bbf5/tools/cache/reflector.go:98: Failed to list *v1beta1.Ingress: Get https://192.168.3.101:6443/apis/extensions/v1beta1/ingresses?limit=500&resourceVersion=0: dial tcp 192.168.3.101:6443: connect: no route to host
traefik_1    | E0421 12:30:12.625449       1 reflector.go:125] pkg/mod/k8s.io/client-go@v0.0.0-20190718183610-8e956561bbf5/tools/cache/reflector.go:98: Failed to list *v1alpha1.Middleware: Get https://192.168.3.101:6443/apis/traefik.containo.us/v1alpha1/middlewares?limit=500&resourceVersion=0: dial tcp 192.168.3.101:6443: connect: no route to host
traefik_1    | E0421 12:30:12.625492       1 reflector.go:125] pkg/mod/k8s.io/client-go@v0.0.0-20190718183610-8e956561bbf5/tools/cache/reflector.go:98: Failed to list *v1alpha1.IngressRoute: Get https://192.168.3.101:6443/apis/traefik.containo.us/v1alpha1/ingressroutes?limit=500&resourceVersion=0: dial tcp 192.168.3.101:6443: connect: no route to host
traefik_1    | E0421 12:30:12.625531       1 reflector.go:125] pkg/mod/k8s.io/client-go@v0.0.0-20190718183610-8e956561bbf5/tools/cache/reflector.go:98: Failed to list *v1alpha1.TraefikService: Get https://192.168.3.101:6443/apis/traefik.containo.us/v1alpha1/traefikservices?limit=500&resourceVersion=0: dial tcp 192.168.3.101:6443: connect: no route to host
traefik_1    | E0421 12:30:12.625572       1 reflector.go:125] pkg/mod/k8s.io/client-go@v0.0.0-20190718183610-8e956561bbf5/tools/cache/reflector.go:98: Failed to list *v1alpha1.TLSOption: Get https://192.168.3.101:6443/apis/traefik.containo.us/v1alpha1/tlsoptions?limit=500&resourceVersion=0: dial tcp 192.168.3.101:6443: connect: no route to host
traefik_1    | E0421 12:30:12.625610       1 reflector.go:125] pkg/mod/k8s.io/client-go@v0.0.0-20190718183610-8e956561bbf5/tools/cache/reflector.go:98: Failed to list *v1alpha1.IngressRouteTCP: Get https://192.168.3.101:6443/apis/traefik.containo.us/v1alpha1/ingressroutetcps?limit=500&resourceVersion=0: dial tcp 192.168.3.101:6443: connect: no route to host

```

### About k3s logs


The installation script will auto-detect if your OS is using systemd or openrc and start the service. When running with openrc, logs will be created at /var/log/k3s.log.

When running with systemd, logs will be created in /var/log/syslog and viewed using journalctl -u k3s.


