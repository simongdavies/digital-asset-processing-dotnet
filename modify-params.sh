#!/usr/bin/env bash
export JQ_FILTER=".parameters.defaultResourceNamePrefix.value=$PREFIX | .parameters.storageAccountName.value=$STORAGE | .parameters.cosmosAccountName.value=$COSACCNAME | .parameters.cosmosCollectionName.value=$COSCOLLNAME | .parameters.cosmosDatabaseName.value=$COSDBNAME | .parameters.applicationInsightsName.value=$APPINS | .parameters.functionAppName.value=$FUNCNAME | .parameters.webAppName.value=$WEBAPPNAME"

#sed -i.bu -e '' "s/defaultResourceNamePrefix string/defaultResourceNamePrefix string = $DEFAULTRESOURCENAMEPREFIX/g" src/arm/main.bicep
#cat src
# jq --arg PREFIX ${DEFAULTRESOURCENAMEPREFIX} --arg STORAGE ${STORAGEACCOUNTNAME} --arg COSACCNAME ${COSMOSACCOUNTNAME} --arg COSCOLLNAME ${COSMOSCOLLECTIONNAME} --arg COSDBNAME ${COSMOSDATABASENAME} --arg APPINS ${APPLICATIONINSIGHTSNAME} --arg FUNCNAME ${FUNCTIONAPPNAME} --arg WEBAPPNAME ${WEBAPPNAME} "${JQ_FILTER}" src/arm/azuredeploy.parameters.json >> src/arm/modified-parameters.json
#jq --arg PREFIX ${DEFAULTRESOURCENAMEPREFIX} "${JQ_FILTER}" main.json >> modified-template.json