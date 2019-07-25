#!/bin/bash

if [ "$1" == "" ];
then
echo "Echo input Project Name"
echo "Script Usage: $0 <project-name> "
exit 1
fi

sudo yum install -y kubectl gcloud google-cloud-sdk-app-engine-grpc google-cloud-sdk-pubsub-emulator google-cloud-sdk-app-engine-go google-cloud-sdk-cloud-build-local google-cloud-sdk-datastore-emulator google-cloud-sdk-app-engine-python google-cloud-sdk-cbt google-cloud-sdk-bigtable-emulator google-cloud-sdk-datalab google-cloud-sdk-app-engine-java

#Project creation
projectName=$1
gcloud projects create $projectName --set-as-default
gcloud config set compute/zone "us-central1-a"
echo "gcp $projectName is created in zone us-central1-a"

#CLuster Creation
gcloud container clusters create "my-first-cluster-1" --zone "us-central1-a"

#To Setup kube config
gcloud container clusters get-credentials "my-first-cluster-1"

curl -o get_helm.sh https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get
chmod +x get_helm.sh
./get_helm.sh

kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller --wait
helm install --name nginx-ingress stable/nginx-ingress --set rbac.create=true --set controller.publishService.enabled=true
kubectl create namespace staging
kubectl create namespace production

#Deploying application to Staging Namespace

echo "########### Staging Service to Browse #############"
kubectl config use-context staging
kubectl apply -f guestbook-all-in-one.yaml
kubectl get svc frontend -n staging
echo "###################################################"

echo "########### Production Service to Browse #############"
kubectl config use-context production
kubectl apply -f guestbook-all-in-one.yaml 
kubectl get svc frontend -n production
echo "###################################################"

# Deployment Autoscalling on CPU Percentage
#kubectl autoscale deployment frontend --min=2 --max=10 --cpu-percent=80
