# TERAKI Exercise


## 0. Prerequisites

Make shure you have the necessary permissions to create the EKS cluster.  
You have installed `kubectl`, `helm 3`, `awscli` and `aws-iam-authenticator`.


## 1. Build EKS cluster using terraform

Go to the `terraform` directory.  
Specify `access_key` and `secret_key` in the `provider.tf` or export environment variables:
```
export AWS_ACCESS_KEY_ID="AKIxxx"
export AWS_SECRET_ACCESS_KEY="xxx"
```

Change variables in the `variables.tf` file and run the following commands to setup EKS cluster:
```
terraform init
terraform apply
```

Generate the configuration for the kubectl and save it to the `~/.kube/config`
```
terraform output kubeconfig > ~/.kube/config
```


## 2. Deploy Grafana application to the EKS cluster

Make sure you have the helm version 3.
```
helm version --short
```

Add and update the stable charts repo
```
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update
```

> You can change the default `name` and `namespace` to install the multiply Grafana applications.  
> Check the [4. Persistent storage](#4-persistent-storage) and [5. Exposing Grafana to the internet](#5-exposing-grafana-to-the-internet) for the details about parameters.

Create a new namespace:
```
kubectl create ns demo
```

To install the Grafana application from the helm chart, check the following parameters and run `helm install`.
```
helm install grafana-demo stable/grafana \
    --namespace demo \
    --set name=grafana-demo \
    --set service.type=ClusterIP \
    --set persistence.enabled=true \
    --set persistence.size=1Gi \
    --set ingress.enabled=true \
    --set "ingress.annotations.kubernetes\.io/ingress\.class=nginx"
```

Follow the instructions in the helm output to get the admin password and service IP address.


## 3. Exposing Grafana UI to the localhost

To expose the Grafana UI to the localhost use the following command:
```
kubectl port-forward service/grafana-demo 3000:80
```

The Grafana UI will be available on the port 3000. <http://localhost:3000>


## 4. Persistent storage

We have enabled the persistent storage for the Grafana deployment. By default it will be use a `pvc` persistence type.  
To change the size of the persistent volume claim, change the `persistence.size` parameter in the `helm install` command.


## 5. Exposing Grafana to the internet

### Install the Nginx ingress controller

To install the nginx-ingress from the heml chart use the following command.
The `controller.service.type` will be set to `LoadBalancer` by default.
```
helm install nginx-demo stable/nginx-ingress --namespace demo
```

### AWS LoadBalancer and Ingress resource

Get the AWS LoadBalancer DNS name:
```
kubectl get svc nginx-demo-nginx-ingress-controller
```

And patch the ingress resource:
```
kubectl patch ingress grafana-demo --type=json \
    -p='[{"op": "replace", "path": "/spec/rules/0/host", "value": "xxx-NNN.eu-central-1.elb.amazonaws.com"}]'
```

Grafana UI will be available by the LoadBalancer DNS.


### 6. SSL/TLS certificate

Get a new SSL/TLS certificate from the Let's Encript or other SSL provider and add it to the namespace
```
kubectl -n demo create secret tls frontend-ssl --key certificate.key --cert certificate-bundle.crt
```

Apply the new ingress resource
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
  name: grafana-demo
  namespace: demo
spec:
  tls:
  - hosts:
    - "xxx-NNN.eu-central-1.elb.amazonaws.com"
    secretName: frontend-ssl
  rules:
  - host: xxx-NNN.eu-central-1.elb.amazonaws.com
    http:
      paths:
      - backend:
          serviceName: grafana-demo
          servicePort: 80
        path: /
```
