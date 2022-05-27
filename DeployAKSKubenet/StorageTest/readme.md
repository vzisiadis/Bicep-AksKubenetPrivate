# notes

- Get kube context
` az aks get-credentials -g rg-MyOrg-AppName-Networking-dev -n aks001`

check strage classes
`kubectl get sc`

## preliminary setup for PV/PVC
- Create a storage account.
- Create a file share in the storage account.
- Create a kubernetes secret containing the storage account name and primary key. This secret is used by the azureFile volume definition to mount the file share from the pod(s).

```bash
# Create a storage account
STG_ACCOUNT_NAME=staks001pv202111
AKS_WORKSHOP_RG=rg-MyOrg-AppName-Networking-dev
# az storage account create --resource-group $AKS_WORKSHOP_RG --name $STG_ACCOUNT_NAME --sku Premium_LRS --kind FileStorage

# Create a file share in the storage account
STG_CONN_STRING=$(az storage account show-connection-string --name $STG_ACCOUNT_NAME --resource-group $AKS_WORKSHOP_RG --output tsv)
az storage share create --name data --connection-string $STG_CONN_STRING --output tsv

# (optional) Use the Azure portal to view the storage account and the 'data' file share.

# Create a kubernetes secret to hold the primary key to the storage account
STG_ACCOUNT_KEY=$(az storage account keys list --account-name $STG_ACCOUNT_NAME --query "[0].value" -o tsv)
kubectl create secret generic azure-storage --from-literal=azurestorageaccountname=$STG_ACCOUNT_NAME --from-literal=azurestorageaccountkey=$STG_ACCOUNT_KEY
```

- get the sample yaml from 
` curl -o pvc-test.yaml https://raw.githubusercontent.com/thotheod/aks-levelup/main/storage/04-shared-storage.yaml `

- apply it
` kubectl apply -f pvc-test.yaml `

- and then run 
` kubectl get svc -w `


```bash
# Show the persistent volume
kubectl get pv
kubectl describe pv task-pv-volume

# Show the persistent volume claim
kubectl get pvc
kubectl describe pvc file-storage-claim
```