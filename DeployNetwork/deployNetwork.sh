#!/bin/bash

# Variables
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
blue='\e[1;34m%s\e[0m\n'

# Set your Azure Subscription
SUBSCRIPTION=xxxxxxxxxxxxxxxxxxxxxxxxxx

DEPLOYMENT_NAME=deployNetwork

# General Settings
SETTINGS_FILE="../general.parameters.json"
ENVIRONMENT=$(cat $SETTINGS_FILE | jq -r .parameters.environment.value)
LOCATION=$(cat $SETTINGS_FILE | jq -r .parameters.location.value)
APP_PREFIX=$(cat $SETTINGS_FILE | jq -r .parameters.appPrefix.value)

PARAM_FILE="./${DEPLOYMENT_NAME}.parameters.${ENVIRONMENT}.json"
RG_NAME="rg-${APP_PREFIX}-Networking-${ENVIRONMENT}"

## TO DO: Replace the values in parameters files with variables


# Code - do not change anything here on deployment
# 1. Set the right subscription
printf "$blue" "*** Setting the subsription to $SUBSCRIPTION ***"
az account set --subscription "$SUBSCRIPTION"

# 2. Create main Resource group if not exists
az group create --name $RG_NAME --location $LOCATION
printf "$green" "*** Resource Group $SUBSCRIPTION created (or Existed) ***"


# 4. start the BICEP deployment
printf "$blue" "starting BICEP deployment for ENV: $ENVIRONMENT"
az deployment group create \
    -f ./$DEPLOYMENT_NAME.bicep \
    -g $RG_NAME \
    -p $PARAM_FILE

printf "$green" "*** Deployment finished for ENV: $ENVIRONMENT.  ***"
printf "$green" "***************************************************"

# get the outputs of the deployment
outputs=$(az deployment group show --name $DEPLOYMENT_NAME -g $RG_NAME --query properties.outputs)

# store them in variables
aksSubnetID=$(jq -r .aksSubnetID.value <<<$outputs)
vnetName=$(jq -r .vnetName.value <<<$outputs)
agicSubnetID=$(jq -r .agicSubnetID.value <<<$outputs)

printf "$green" "AKS Subnet ID:   $aksSubnetID"
printf "$green" "Vnet Name:       $vnetName"
printf "$green" "AGIC Subnet ID:       $agicSubnetID"


printf "$blue" "*** Updating respective values in AKS Deployment file ***"
printf "$blue" "*********************************************************"

cat ../DeployAKSKubenet/deployAks.parameters.json | jq --arg akssubnet "$aksSubnetID" --arg vnetname "$vnetName" --arg agicsubnet "$agicSubnetID" '.parameters.aksSnetID.value = $akssubnet | .parameters.vnetName.value = $vnetname | .parameters.agicSubnet.value = $agicsubnet' > ../DeployAKSKubenet/deployAks.parameters.json
printf "$green" "*** Completed ***"
