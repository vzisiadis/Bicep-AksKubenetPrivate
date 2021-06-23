#!/bin/bash

# Variables
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
blue='\e[1;34m%s\e[0m\n'

# Set your Azure Subscription
SUBSCRIPTION=0a52391c-0d81-434e-90b4-d04f5c670e8a

# choice of dev|prod
ENVIRONMENT=local
APP_PREFIX=TestAKS
RG_NAME="rg-${APP_PREFIX}-Cluster-${ENVIRONMENT}"
RG_VNET_NAME="rg-${APP_PREFIX}-Networking-${ENVIRONMENT}"
VNET_NAME="vnet-${ENVIRONMENT}-AKSPrivateKubenet"
LOCATION=northeurope
DEPLOYMENT_NAME=deployAks
PARAM_FILE="./${DEPLOYMENT_NAME}.parameters.${ENVIRONMENT}.json"


ATTACH_ACR=$(cat $PARAM_FILE | jq -r .parameters.attachACR.value)

the_world_is_flat=true
# ...do something interesting...
if [ "$ATTACH_ACR" = true ] ; then
    echo 'attach it'
fi
