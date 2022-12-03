#!/bin/bash
kind_download_url="https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-amd64"
kind_image="kindest/node:v1.23.0"
seconds=60

brewcmd=$(which brew)


if [ -z "${brewcmd}" ]; then
    echo "No Homebrew: try https://brew.sh"
    echo "See https://crossplane.io/docs for other Crossplane install options"
    exit 1
fi

executables="docker kind kubectl helm"
for e in $executables; do
    [ -z "$(which "$e")" ] && missing+="$e "
done

missing=
for e in $executables; do
    [ -z "$(which "$e")" ] && missing+="$e "
done

[ -n "${brewcmd}" ] && for m in $missing; do
    case $m in
    docker)
        echo "Installing Docker and Docker Desktop"
        env -i bash -c 'brew install --cask docker'
        echo "Re-run this script after completing install of Docker Desktop"
        open /Applications/Docker.app
        exit 2
        ;;
    kind)
        echo "Installing Kind"
        env -i bash -c 'brew install kind'
        echo "Kind install complete"
        ;;
    kubectl)
        echo "Installing kubectl"
        env -i bash -c 'brew install kubectl'
        echo "Kubectl install complete"
        ;;
    helm)
        echo "Installing helm"
        env -i bash -c 'brew install helm'
        echo "Helm install complete"
        ;;
    esac
done

echo "Starting local Kubernetes cluser with Kind..."
kind create cluster --image $kind_image --name sop-local --wait 5m || \
    { echo "Start failed--try 'kind delete cluster -n crossplane'"; exit 1; }

echo "Using Helm to install Crossplane on local Kubernetes cluster..."
helm repo add \
    crossplane-stable https://charts.crossplane.io/stable
helm repo update

helm install crossplane \
    crossplane-stable/crossplane \
    --namespace crossplane-system \
    --create-namespace

echo "$ kubectl get pods -n crossplane-system"
kubectl get pods -n crossplane-system

echo "Waiting $seconds seconds for Crossplane resources to become available..."
sleep $seconds

echo "$ kubectl api-resources | grep crossplane"
kubectl api-resources | grep crossplane

kubectl apply -f provider.yaml
kubectl apply -f rbac.yaml
kubectl apply -f secret.yaml

echo "Waiting $seconds seconds for Crossplane Providers to become available..."
sleep $seconds
kubectl apply -f providerconfig.yaml

kubectl apply -f definition.yaml
kubectl apply -f composition.yaml

kubectl apply -f configmap.yaml
kubectl apply -f claim.yaml