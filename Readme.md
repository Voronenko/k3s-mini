# Unobtrusive local development with kubernetes, k3s, traefik2

This is followup to my local docker development environment described here https://github.com/Voronenko/traefik2-compose-template.
In addition to classic dockerized projects, I also have number of kubernetes projects. Kubernetes is both resource and money consuming
platform. As I don't always need external cluster, solution I use for local development for kubernetes is https://k3s.io/.

This platform positions itself as a lightweight kubernetes, but truth is that it is one of the smallest certified Kubernetes distribution built for IoT & Edge computing, capable also to be deployed on a prod scale to VMs.

I use k3s in two ways:  I have k3s installed locally on my work notebook, although sometimes I need to deploy locally heavier test workloads, and for that purpose I have two small beasts - two external intel NUCs running ESXi.

By default k3s gets installed with traefik1 as ingress, and if you are satisfied with that setup, you generally can stop reading article.

In my scenario I am involved in multiple projects, in particular classic docker and docker swarm one, and thus I often have situation when traefik is deployed in standalone mode.

So rest of this article dives into configuring external traefik2 as ingress for k3s cluster.

## Installing kubernetes k3s family cluster.

You can start with classic `curl -sfL https://get.k3s.io | sh -`  or you can use k3sup light-weight utility written by https://github.com/alexellis/k3sup.

What would be different for our setup is that we specifically install k3s without traefik component using switch `--no-deploy traefik`

```sh

export CLUSTER_MASTER=192.168.3.100
export CLUSTER_DEPLOY_USER=slavko
k3sup install --ip $CLUSTER_MASTER --user $CLUSTER_DEPLOY_USER --k3s-extra-args '--no-deploy traefik'
```

as a result of the execution you will get connection details necessary to use kubectl. Upon k3s installation you can quickly check if you can see the nodes

```sh
# Test your cluster with - export path to k3s cluster kubeconfig:
export KUBECONFIG=/home/slavko/kubeconfig
kubectl get node -o wide
```

Side note - there is no specific magic with k3s flavor of the kubernetes. You can even start it on your own with docker-compose

```yaml
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

## Configuring traefik2 to work with kubernetes.

As you recall, by that time I usually have traefik2 already present in my system and serving some needs as per https://github.com/Voronenko/traefik2-compose-template.  Now it is time to configure traefik2 kubernetes backend.

Traefik2 does so using CRD - custom resource definition concept (https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/). Latest examples of the definitions can always be found under the link  https://docs.traefik.io/reference/dynamic-configuration/kubernetes-crd/ , but those are for the scenario when traefik2 is also executed as a part of kubernetes workload.

For scenario of the external traefik2 we need only subset of definitions described below.

We are introducing set of custom resource definitions allowing us to describe how our kubernetes service will be exposed outside, `traefik-crd.yaml`:

```yaml
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
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: traefikservices.traefik.containo.us

spec:
  group: traefik.containo.us
  version: v1alpha1
  names:
    kind: TraefikService
    plural: traefikservices
    singular: traefikservice
  scope: Namespaced
```

We also need cluster role `traefik-ingress-controller` giving mostly readonly access to services, endpoints and secrets and custom `traefik.containo.us` group, `traefik-clusterrole.yaml`

```yaml

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
  - apiGroups:
      - traefik.containo.us
    resources:
      - traefikservices
    verbs:
      - get
      - list
      - watch
```

and finally we need system service account `traefik-ingress-controller` associated with previously created `traefik-ingress-controller` cluster role

```yaml
---
kind: ServiceAccount
apiVersion: v1
metadata:
  namespace: kube-system
  name: traefik-ingress-controller

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
    namespace: kube-system
```

Once we apply resources above

```sh
apply:
	kubectl apply -f traefik-crd.yaml
	kubectl apply -f traefik-clusterrole.yaml
  kubectl apply -f traefik-service-account.yaml
```

we are ready to start tuning traefik2

## Pointing traefik2 to k3s cluster

When deployed into Kubernetes, as traefik docs suggest, traefik will read the environment variables KUBERNETES_SERVICE_HOST and KUBERNETES_SERVICE_PORT or KUBECONFIG to construct the endpoint.

The access token will be looked up in /var/run/secrets/kubernetes.io/serviceaccount/token and the SSL CA certificate in /var/run/secrets/kubernetes.io/serviceaccount/ca.crt. Both are provided mounted automatically when deployed inside Kubernetes.

When the environment variables are not found, Traefik will try to connect to the Kubernetes API server with an external-cluster client. In this case, the endpoint is required. Specifically, it may be set to the URL used by kubectl proxy to connect to a Kubernetes cluster using the granted authentication and authorization of the associated kubeconfig.

Traefik2 can be statically configured using any types of the config supported - toml, yaml or commandline switches.

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

On a first run, if you have traefik outside, most likely you will not have access tokens for `traefik-ingress-controller` to specify mytoken. To discover one:

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

```json
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

```txt
eyJhbGciOiJSUzI1NiIsImtpZCI6IjBUeTQyNm5nakVWbW5PaTRRbDhucGlPeWhlTHhxTXZjUDJsRmNacURjVnMifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJ0cmFlZmlrLWluZ3Jlc3MtY29udHJvbGxlci10b2tlbi12emM3diIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJ0cmFlZmlrLWluZ3Jlc3MtY29udHJvbGxlciIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6ImQ5NTc3ZTkxLTdlNjQtNGMwNi1iZDgyLWNkZTk0OWM4MTI1MSIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlLXN5c3RlbTp0cmFlZmlrLWluZ3Jlc3MtY29udHJvbGxlciJ9.Mk8EBS4soO8uX-uSnV3o4qZKR6Iw6bgeSmPhHbJ2fjuqFgLnLh4ggxa-N9AqmCsEWiYjSi5oKAu986UEC-_kGQh3xaCYsUwlkM8147fsnwCbomSeGIct14JztVL9F8JwoDH6T0BOEjn-J9uY8-fUKYL_Y7uTrilhFapuILPsj_bFfgIeOOapRD0XshKBQV9Qzg8URxyQyfzl68ilm1Q13h3jLj8CFE2RlgEUFk8TqYH4T4fhfpvV-gNdmKJGODsJDI1hOuWUtBaH_ce9w6woC9K88O3FLKVi7fbvlDFrFoJ2iVZbrRALPjoFN92VA7a6R3pXUbKebTI3aUJiXyfXRQ
```

external address of the api server  `https://192.168.3.100:6443` as per last response

Again, nothing magic in provided token: this is JWT token and you you can use https://jwt.io/#debugger-io to inspect it's contents

```json
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

As proper configuration is quite important, ensure that both calls to APISERVER return reasonable response.

```sh
export APISERVER=YOURAPISERVER
export TOKEN=YOURTOKEN

curl -X GET $APISERVER/api --header "Authorization: Bearer $TOKEN" --insecure

curl -X GET $APISERVER/api/v1/endpoints --header "Authorization: Bearer $TOKEN" --insecure
```

### Creating additional access token

A controller loop ensures a secret with an API token exists for each service account, that can be discovered like we did previously.
Also you can create additional API tokens for a service account, create a secret of type ServiceAccountToken with an annotation referencing the service account, and the controller will update it with a generated token:

```yaml
---
apiVersion: v1
kind: Secret
namespace: kube-system
metadata:
  name: traefik-manual-token
  annotations:
    kubernetes.io/service-account.name: traefik-ingress-controller
type: kubernetes.io/service-account-token

# Any tokens for non-existent service accounts will be cleaned up by the token controller.

# kubectl describe secrets/traefik-manual-token
```

to create

```sh
kubectl create -f ./traefik-service-account-secret.yaml
kubectl describe secret traefik-manual-token
```

to delete/invalidate


```sh
kubectl delete secret traefik-manual-token
```


### Changes to external traefik2 compose definitions

What changes we need to add to traefik2 configuration we've got on https://github.com/Voronenko/traefik2-compose-template ?

a) New folder `kubernetes_data` where we store `ca.crt` file used to validate calls to kubernetes authority. This is the certificate
that can be found under clusters->cluster->certificate-authority-data of your kubeconfig file.

This volume will be mapped under `/var/run/secrets/kubernetes.io/serviceaccount` for the official traefik2 image

```yaml
    volumes:
    ...
      - ./kubernetes_data:/var/run/secrets/kubernetes.io/serviceaccount
```

and
b) adjust traefik2 kubernetescrd backend providing 3 parameters: endpoint, path to cert and token. Please note, that as your external traefik as a docker container, you need to specify proper accessible endpoint address, and ensure you are doing that in +- secure way.

```yaml
      - "--providers.kubernetescrd=true"
      - "--providers.kubernetescrd.endpoint=https://192.168.3.100:6443"
      - "--providers.kubernetescrd.certauthfilepath=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
      - "--providers.kubernetescrd.token=YOURTOKENWITHOUTANYQUOTES
```

If you did everything right, you should see now something promising on your traefik UI

![alt](https://github.com/Voronenko/k3s-mini/raw/master/docs/traefik_crd.png)

if you do not see one or have issues running traefik up check troubleshouting section.

Now is time to expose some kubernetes service via traefik2 to ensure that traefik2 is actually working as ingress. Let's take our classic
`whoami` service, `whoami-service.yaml`


```yaml
apiVersion: v1
kind: Service
metadata:
  name: whoami

spec:
  ports:
    - protocol: TCP
      name: web
      port: 80
  selector:
    app: whoami

---
kind: Deployment
apiVersion: apps/v1
metadata:
  namespace: default
  name: whoami
  labels:
    app: whoami

spec:
  replicas: 2
  selector:
    matchLabels:
      app: whoami
  template:
    metadata:
      labels:
        app: whoami
    spec:
      containers:
        - name: whoami
          image: containous/whoami
          ports:
            - name: web
              containerPort: 80
```

and expose it in a http or https way, `whoami-ingress-route.yaml` under `whoami.k.voronenko.net` fqdn.

```yaml

apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: ingressroute-notls
  namespace: default
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`whoami.k.voronenko.net`)
      kind: Rule
      services:
        - name: whoami
          port: 80

---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: ingressroute-tls
  namespace: default
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`whoami.k.voronenko.net`)
      kind: Rule
      services:
        - name: whoami
          port: 80
  tls:
    certResolver: default

```

and apply it:

```sh
	kubectl apply -f whoami-service.yaml
	kubectl apply -f whoami-ingress-route.yaml
```

Once applied, you should see smth promising on a traefik dashboard, namely KubernetesCRD backend

![alt](https://github.com/Voronenko/k3s-mini/raw/master/docs/whoami_crd.png)

As you see traefik2 has detected our new workload running on our k3s kubernetes cluster, and moreover it is nicely
co-exists with classic docker workloads we have on the same box, like portainer.

Let's check if traefik2 routes traefik to our kubernetes workload: as you see you can successfully reach whoami workload
on a both http and https endpoints and browser accepts your certificate as a trusted grean seal one.

![alt](https://github.com/Voronenko/k3s-mini/raw/master/docs/whoami_workload.png)

![alt](https://github.com/Voronenko/k3s-mini/raw/master/docs/whoami_pod.png)

Yooohoo, we reached our goal. We have traefik2 configured either on your local notebook or perhaps some dedicated machine in your homelab.
Traefik2 exposes your docker or kubernetes workflow on a http or https endpoints. Traefik2 with optional letsencrypt are responsible for https.


###  Troubleshouting

As you understand, there could be multiple issues. Consider some of the tools for analysis  https://github.com/Voronenko/dotfiles/blob/master/Makefile#L185

In particular I recommend:

a) VMWare octant - powerfull web based kubernetes dashboard that starts using your kubeconfig

b) Rakess - https://github.com/corneliusweig/rakkess standalone tool and also kubectl plugin to show an access matrix for k8s server resources

Inspect credentials for system account

```sh
rakkess --sa kube-system:traefik-ingress-controller

```

c) just kubectl

Reverse task: check which roles are associated with service account

```sh
kubectl get clusterrolebindings -o json | jq -r '
  .items[] |
  select(
    .subjects // [] | .[] |
    [.kind,.namespace,.name] == ["ServiceAccount","kube-system","traefik-ingress-controller"]
  ) |
  .metadata.name'
```

d) Traefik docs - for example kubernetescrd backend has a way more configuration switches.
```txt
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

e) Ensure traefik has enough rights to access apiserver endpoints.

If you are keen which information is queried by traefik: you can see accessed endpoints and order of queriiing by putting some wrong apiserver address in configuration. Having this knowledge, and your traefik kubernetes token you can check that those endpoints are accessible using traefik credentials

```log
traefik_1    | E0421 12:30:12.624877       1 reflector.go:125] pkg/mod/k8s.io/client-go@v0.0.0-20190718183610-8e956561bbf5/tools/cache/reflector.go:98: Failed to list *v1.Endpoints: Get https://192.168.3.101:6443/api/v1/endpoints?limit=500&resourceVersion=0:
traefik_1    | E0421 12:30:12.625341       1 reflector.go:125] pkg/mod/k8s.io/client-go@v0.0.0-20190718183610-8e956561bbf5/tools/cache/reflector.go:98: Failed to list *v1.Service: Get https://192.168.3.101:6443/api/v1/services?limit=500&resourceVersion=0:
traefik_1    | E0421 12:30:12.625395       1 reflector.go:125] pkg/mod/k8s.io/client-go@v0.0.0-20190718183610-8e956561bbf5/tools/cache/reflector.go:98: Failed to list *v1beta1.Ingress: Get https://192.168.3.101:6443/apis/extensions/v1beta1/ingresses?limit=500&resourceVersion=0:
traefik_1    | E0421 12:30:12.625449       1 reflector.go:125] pkg/mod/k8s.io/client-go@v0.0.0-20190718183610-8e956561bbf5/tools/cache/reflector.go:98: Failed to list *v1alpha1.Middleware: Get https://192.168.3.101:6443/apis/traefik.containo.us/v1alpha1/middlewares?limit=500&resourceVersion=0:
traefik_1    | E0421 12:30:12.625492       1 reflector.go:125] pkg/mod/k8s.io/client-go@v0.0.0-20190718183610-8e956561bbf5/tools/cache/reflector.go:98: Failed to list *v1alpha1.IngressRoute: Get https://192.168.3.101:6443/apis/traefik.containo.us/v1alpha1/ingressroutes?limit=500&resourceVersion=0:
traefik_1    | E0421 12:30:12.625531       1 reflector.go:125] pkg/mod/k8s.io/client-go@v0.0.0-20190718183610-8e956561bbf5/tools/cache/reflector.go:98: Failed to list *v1alpha1.TraefikService: Get https://192.168.3.101:6443/apis/traefik.containo.us/v1alpha1/traefikservices?limit=500&resourceVersion=0:
traefik_1    | E0421 12:30:12.625572       1 reflector.go:125] pkg/mod/k8s.io/client-go@v0.0.0-20190718183610-8e956561bbf5/tools/cache/reflector.go:98: Failed to list *v1alpha1.TLSOption: Get https://192.168.3.101:6443/apis/traefik.containo.us/v1alpha1/tlsoptions?limit=500&resourceVersion=0:
traefik_1    | E0421 12:30:12.625610       1 reflector.go:125] pkg/mod/k8s.io/client-go@v0.0.0-20190718183610-8e956561bbf5/tools/cache/reflector.go:98: Failed to list *v1alpha1.IngressRouteTCP: Get https://192.168.3.101:6443/apis/traefik.containo.us/v1alpha1/ingressroutetcps?limit=500&resourceVersion=0:

```

f) k3s logs itself

The installation script will auto-detect if your OS is using systemd or openrc and start the service. When running with openrc, logs will be created at /var/log/k3s.log. When running with systemd, logs will be created in /var/log/syslog and viewed using journalctl -u k3s.

There you might get some hints, like
```txt
кві 21 15:42:44 u18d k3s[612]: E0421 15:42:44.936960     612 authentication.go:104] Unable to authenticate the request due to an error: invalid bearer token
```
which would provide you are clue on traefik startups issue with k8s

Good luck in your journey!

Related code can be found on https://github.com/Voronenko/k3s-mini
