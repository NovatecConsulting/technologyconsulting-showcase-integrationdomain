# Helm Charts for Confluent Platform and additional components
This repository contains Helm Charts for the deployment of Confluent Platform components on a Minikube cluster.

## Prerequisites
* Install Minikube:
To use Minikube, a Hypervisor (e.g. VirtualBox) or Docker is needed. Perform the steps of the [installation guide](http://www.minikube.sigs.k8s.io/docs/start/) until the second step according to your operating system.
Start a minikube cluster:
```
minikube start 
```
* Install [kubectl](https://www.kubernetes.io/de/docs/tasks/tools/install-kubectl/#kubectl-installieren).

* Install [Helm](https://www.helm.sh/docs/intro/install/).

* Change into the directory where you want to clone the project to and download it:
```
git clone https://github.com/NovatecConsulting/technologyconsulting-kafka-k8
```

## Quickstart
When the minikube cluster is started, enable the registry:
```
minikube addons enable registry
```
To install all components, run the setup.sh script:
```
./setup.sh up
```
When finished or for re-deployment:
```
./setup.sh down
```
To use MongoDB, PostgreSQL and HiveMQ with the help of the Kafka Connect API, several Connectors need to be deployed.
Kafka Connect always needs several minutes to become available in minikube, depending on your hardware.
For this reason, the Connectors need to be deployed in the next step as soon as Kafka Connect is ready.
To check for Connect being available:
```
kubectl logs -f <uniquePodName> kafka-connect-server
```
Deploy the connectors:
```
helm install connector-deploy ./deployments/deploy/connector-deploy
```
### Useful Commands
To install helm charts in the ./charts/ subdirectory:
```
helm install <release-name> <./path/to/charts>
```
Show all pods:
```
kubectl get pods
```
Uninstall a chart:
```
helm uninstall <release-name>
```
Stop minikube:
```
minikube stop
```
Delete minikube:
```
minikube delete
```

### Troubleshooting
If you encouter an "ImagePullBackOff" error or another kind of error indicating that the image for Kafka Connect and Connect-Deploy cannot be found,
this might be because of a wrong port configuration.

When enabling the registry, minikube does not always use the same port. To check the exposed port:
```
docker ps
```
You will see a list of ports for minikube. Look for a port-pair containing 5000.
The other port-value should be the same as in the files "build-connect-image.sh", "build-deploy-image.sh" and as in the functions "buildDeployImage" and 
"buildConnectImage" in the setup.sh script.

