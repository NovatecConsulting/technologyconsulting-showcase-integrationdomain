# Showcase: Integration Domain

Inspired by a customer project, the PA-TC Showcase was expanded to include the integration domain in addition to the order domain, supplier domain and manufacture domain.
While the original goal was to run Kafka in the cloud together with various connectors, the focus has shifted over time. The showcase examined the deployment of Kafka Connect in the cloud using a secret provider and what differences have to be considered in terms of PLAINTEXT and SSL.

The question of how to use credentials with Kafka will certainly arise again in the future. The most important points and "pitfalls" are briefly explained below.

## Prerequisites
The intention of this showcase was to run it in additon to the PA-TC Showcase. Therefore, either the PA-TC Showcase environment must be up and running in Azure to test the Integration Showcase or you have to provide similar components.
The PA-TC Showcase environment consists of the following domains:
- Order Domain
- Supplier Domain
- Manufacture Domain
- Infrastructure Repository

To deploy the components, e.g. a Github Actions pipeline in combination with Github Secrets can be used.

The Kafka Connect component, which is deployed with this repository, is accessing a PostgreSQL Database and needs a Kafka Broker to connect to. This Kafka Broker/Cluster can either be self-managed or can also be a Confluent Cloud Cluster.

[For users with developer access to this repository only]: To deploy the components in this repository, trigger the *helminstall* or *helminstall_Ssl* Actions pipeline manually.

## Scenario
Two possible scenarios could be:
1. A project uses the self-managed community version of the Confluent Platform and is running in Azure, i.e. all components including Kafka Connect need to be deployed, e.g. by Helm Charts. Important detail: The default security protocol is PLAINTEXT.
2. A project runs on Confluent Cloud but additional connectors are needed that are not supported by Confluent (e.g. Debezium Connectors). A self-managed Kafka-Connect component can be used which is running in Azure. Important detail: Confluent Cloud's security protocol is SSL.


## Using a Secret Provider

A ConfigProvider can be used to avoid writing credentials in plain text into configuration files. When working with a cloud environment, in most cases there already is a key vault available to store the secrets. Through implementing the ConfigProvider class provided by Kafka, those secrets are accessible within the configuration files. 

This repository uses the [Azure Secret Provider by Lenses.io](https://docs.lenses.io/4.2/integrations/connectors/secret-providers/azure/).
 

## 1. Self-Managed/PLAINTEXT
**helmInstall.yaml pipeline**
### Helm Charts

[Confluent's Helm Charts](https://github.com/confluentinc/cp-helm-charts) **only support the Enterprise version** of the Confluent Platform. For the **Community version**, is has to be considered that: 

- The default value for the Kafka broker image is *confluentinc/cp-server*. This value cannot be overwritten with a community image via the *values.yaml* file without further additional changes. 
In the chart itself, the metrics reporter must be commented out in *statefulset.yaml* because it is not included in the community version:

```
     # name: KAFKA_METRIC_REPORTERS
     # value: "io.confluent.metrics.reporter.ConfluentMetricsReporter"
     # - name: CONFLUENT_METRICS_REPORTER_BOOTSTRAP_SERVERS
     # value: {{ printf "PLAINTEXT://%s:9092" (include "cp-kafka.cp-kafka-headless.fullname" .) | quote }}
```

- Control Center is of course not available when using the community version and must be removed from the parent *requirements.yaml* (like other unneeded components).

### Configuration of the Secret Provider

First, a custom image needs to be built which includes the secret provider jar-file (*/resources/k8s/deployments/confluent-platform/Dockerfile.connect*).

Like Lenses also describes in the documentation of the secret provider, it is not sufficient to just download the connector. In general, connectors are downloaded into a directory which is accessed using classloading isolation to avoid library conflicts (*/usr/share/confluent-hub-components/secret-provider*). But the Azure KeyVault SDK uses the default system classloader instead of the plugin's classloader, so that the secret provider needs to be added to the classpath to ensure that the HttpClient can be found:
```
ENV CLASSPATH=/usr/share/confluent-hub-components/secret-provider/*
```

Next, some properties must be added as configuration overrides in *connect.values.yaml*:
```
    "config.providers": "azure"
    "config.providers.azure.class": "io.lenses.connect.secrets.providers.AzureSecretProvider"
    "config.providers.azure.param.azure.auth.method": "credentials"
    "config.providers.azure.param.file.dir": "/connector-files/azure"
    "config.providers.azure.param.azure.client.id":
    "config.providers.azure.param.azure.secret.id":
    "config.providers.azure.param.azure.tenant.id":
```
The Azure Client, Secret and Tenant ID need to be injected to identify the Connect worker at your Azure cluster. 
In this repository, the credentials are stored using Github Secrets and are injected using a Github Actions pipeline at */.github/workflows/helmInstall/*.

## 2. Confluent-Cloud/SSL
**helminstall_Ssl.yaml pipeline**
### Configuration of the Secret Provider
The configuration from above will fail when the SSL protocol is used. Read more details about this [issue](https://github.com/confluentinc/cp-docker-images/issues/828#issuecomment-588027887). There are two possibilities to resolve this:

1. Connect will fail when the ensure.sh script is run at start-up, because the check that is performed in this script is trying to connect to the Kafka Broker - which is not possible without the connection credentials. Therefore, the script can be replaced with */resources/k8s/deployments/confluent-platform/kafka-connect/include/etc/confluent/docker* when building the image in *Dockerfile.connect*.
2. The solution that is implemented in this repository uses the standard Confluent image without modifications at the ensure script. The ConfigProvider needs to be added to the CUB_CLASSPATH to make sure that it is found by the 'cub' tool. The CUB_CLASSPATH needs to include:
  - reference to the KafkaReadyCommand -> /usr/share/java/cp-base-new/*
  - reference to Kafka Connect -> /usr/share/java/kafka/*
  - reference to the Jar-file -> /usr/share/confluent-hub-components/secret-provider/*

The complete CUB_CLASSPATH will look like:
```
ENV CUB_CLASSPATH='"/etc/confluent/docker/docker-utils.jar:/usr/share/java/kafka/*:/usr/share/confluent-hub-components/secret-provider/*"'
```
Note the different quotation marks and that no environment variables are used within the path to make sure that the variable is picked up correctly.

When the current version (2.1.6) of the Lenses Secret Provider is used and the current version of Kafka (6.6.1), this will still fail because of conflicting Scala versions (-> good example why classloading isolation is important).
This can be resolved by changing the Scala version of the Secret Provider to fit with the Scala version of Kafka or by downgrading Kafka Connect to version 5.5.1 (where the same Scala version is used as in the secret provider).


