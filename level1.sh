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
billing_account=`gcloud alpha billing accounts list | sed '1d' | awk '{print $1}'`

if [ "$billing_account" == "" ];
then
echo "No Billing acount found in your config"
echo "Please config gcloud in local terminal"
exit 1
fi

get_status(){
if [ $? -eq '0' ];
then
echo "SUCCESS"
else
echo "FAILED"
exit 1
fi
}


gcloud projects create $projectName --set-as-default
get_status
gcloud config set compute/zone "us-central1-a"
get_status
echo "gcp $projectName is created in zone us-central1-a"

#CLuster Creation
gcloud alpha billing projects link $projectName --billing-account $billing_account
get_status
gcloud container clusters create "$1" --zone "us-central1-a" --enable-basic-auth
get_status

#To Setup kube config
gcloud container clusters get-credentials "$1"
get_status

curl -o get_helm.sh https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get
chmod +x get_helm.sh
./get_helm.sh

kubectl create serviceaccount --namespace kube-system tiller
get_status
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
get_status
helm init --service-account tiller --wait
get_status
helm install --name nginx-ingress stable/nginx-ingress --set rbac.create=true --set controller.publishService.enabled=true
get_status
kubectl create namespace staging
get_status
kubectl create namespace production
get_status

#Deploying application to Staging Namespace

echo "########### Staging Service to Browse #############"
kubectl config set-context --current --namespace=staging
kubectl apply -f guest-book.yaml
sleep 10 
kubectl get svc frontend -n staging
echo "###################################################"

echo "########### Production Service to Browse #############"
kubectl config set-context --current --namespace=production
kubectl apply -f guest-book.yaml
sleep 10 
kubectl get svc frontend -n production
echo "###################################################"

# Deployment Autoscalling on CPU Percentage

#kubectl autoscale deployment frontend --min=2 --max=10 --cpu-percent=80
