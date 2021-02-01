set -euxo pipefail;
az login --identity -u  ${AZURE_USER_MSI_RESOURCE_ID}
RG=$(az group list --output tsv --query '[0].name')
az deployment group create --resource-group ${RG} --name testdeploy --template-file src/arm/azuredeploy.json --parameters @src/arm/azuredeploy.parameters.json