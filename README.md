# DevopsLevel1
Take home test for DevOps/SysOps role – Level#1 --

Prerequests:
- gcloud
- gcloud billing account
- CentOS 7+

HOWTO:
- gcloud init --console-only 
- run `level1.sh <project-id>`

# AutoScalling:
- Please use below command once the cluster is fully deployed with application pods
- kubectl autoscale deployment frontend --min=2 --max=10 --cpu-percent=2
- Using CPU-Percent=2 to get the instant result on incresing pods.

# Increasing Load
- run `while true; do curl http://<LOAD BALANCER_IP>/; done`
