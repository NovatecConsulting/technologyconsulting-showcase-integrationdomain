#!/bin/bash
set -e

echo $ARM_CLIENT_ID
echo $ARM_CLIENT_SECRET
echo $ARM_TENANT_ID

az login --service-principal \
    -u $ARM_CLIENT_ID \
    -p $ARM_CLIENT_SECRET \
    --tenant $ARM_TENANT_ID \
    --allow-no-subscriptions > /dev/null

# don't hardcode tc-showcase-test here TODO
DBUSER=$(az keyvault secret show --vault-name "vault-tc-showcase-test" --name "database-user" --query value -o tsv)

DBPWD=$(az keyvault secret show --vault-name "vault-tc-showcase-test" --name "database-password" --query value -o tsv)

DBFQDN=$(az keyvault secret show --vault-name "vault-tc-showcase-test" --name "database-fqdn" --query value -o tsv)

INGRESSFQDN=$(az keyvault secret show --vault-name "vault-tc-showcase-test" --name "ingress-fqdn" --query value -o tsv)

CONFLUENT_CLOUD_KEY=$(az keyvault secret show --vault-name "vault-tc-showcase-test" --name "confluent-cloud-key" --query value -o tsv)

CONFLUENT_CLOUD_SECRET=$(az keyvault secret show --vault-name "vault-tc-showcase-test" --name "confluent-cloud-secret" --query value -o tsv)

CONFLUENT_CLOUD_BOOTSTRAP_SERVERS=$(az keyvault secret show --vault-name "vault-tc-showcase-test" --name "confluent-cloud-bootstrap-server" --query value -o tsv)
# put values to Github's env stage
# this not a safe solution
echo "DBUSER=$DBUSER" >> $GITHUB_ENV
echo "DBPWD=$DBPWD" >> $GITHUB_ENV
echo "DBFQDN=$DBFQDN" >> $GITHUB_ENV
echo "INGRESSFQDN=$INGRESSFQDN" >> $GITHUB_ENV

echo "CONFLUENT_CLOUD_BOOTSTRAP_SERVERS=$CONFLUENT_CLOUD_BOOTSTRAP_SERVERS" >> $GITHUB_ENV
echo "CONFLUENT_CLOUD_KEY=$CONFLUENT_CLOUD_KEY" >> $GITHUB_ENV
echo "CONFLUENT_CLOUD_SECRET=$CONFLUENT_CLOUD_SECRET" >> $GITHUB_ENV
