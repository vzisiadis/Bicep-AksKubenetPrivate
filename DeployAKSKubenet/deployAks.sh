#!/bin/bash

# Variables
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
blue='\e[1;34m%s\e[0m\n'

# Set your Azure Subscription
SUBSCRIPTION=xxxxxxxxxxxxxxxxxxxxxx

# choice of dev|prod
ENVIRONMENT=local
RG_NAME="rg-AksPrivateKubenet-${ENVIRONMENT}"
LOCATION=northeurope
DEPLOYMENT_NAME=deployAks
PARAM_FILE="./${DEPLOYMENT_NAME}.parameters.${ENVIRONMENT}.json"



# Code - do not change anything here on deployment
# 1. Set the right subscription
printf "$blue" "*** Setting the subsription to $SUBSCRIPTION ***"
az account set --subscription "$SUBSCRIPTION"

# 2. Create main Resource group if not exists
az group create --name $RG_NAME --location $LOCATION
printf "$green" "*** Resource Group $SUBSCRIPTION created (or Existed) ***"


# 4. start the BICEP deployment
printf "$blue" "starting BICEP AKS deployment for ENV: $ENVIRONMENT"
az deployment group create \
    -f ./$DEPLOYMENT_NAME.bicep \
    -g $RG_NAME \
    -p $PARAM_FILE

printf "$green" "*** Deployment finished for ENV: $ENVIRONMENT.  ***"
printf "$green" "***************************************************"

# get the outputs of the deployment
outputs=$(az deployment group show --name $DEPLOYMENT_NAME -g $RG_NAME --query properties.outputs)

# store them in variables
aksID=$(jq -r .aksID.value <<<$outputs)
aksNodesRG=$(jq -r .aksNodesRG.value <<<$outputs)

printf "$green" "AKS  ID:           $aksID"
printf "$green" "AKS managed RG:    $aksNodesRG"
