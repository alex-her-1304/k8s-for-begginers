#/bin/bash
minikube start --driver=virtualbox --cpus=4 --memory=8192 start --nodes 3
minikube addons enable metrics-server
minikube addons enable ingress
k create namespace monitoring
helm install kube-prometeus-stack prometheus-community/kube-prometheus-stack -n monitoring \
--set 'grafana.ingress.enabled=true' \
--set 'grafana.ingress.hosts[0]=grafana.craftech.io'
helm install --values values.yaml loki grafana/loki -n monitoring
# editar los 
k edit statefulset loki-minio -n monitoring