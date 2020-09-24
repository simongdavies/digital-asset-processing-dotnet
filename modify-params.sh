#!/usr/bin/env bash


#sed -i.bu -e '' "s/defaultResourceNamePrefix string/defaultResourceNamePrefix string = $DEFAULTRESOURCENAMEPREFIX/g" src/arm/main.bicep
#cat src
jq --arg PREFIX ${DEFAULTRESOURCENAMEPREFIX} --arg STORAGE ${STORAGEACCOUNTNAME} --arg COSACCNAME ${COSMOSACCOUNTNAME} --arg COSCOLLNAME ${COSMOSCOLLECTIONNAME} --arg COSDBNAME ${COSMOSDATABASENAME} --arg APPINS ${APPLICATIONINSIGHTSNAME} --arg FUNCNAME ${FUNCTIONAPPNAME} --arg WEBAPPNAME ${WEBAPPNAME} "${JQ_FILTER}" src/arm/azuredeploy.parameters.json >> src/arm/modified-parameters.json
#jq --arg PREFIX ${DEFAULTRESOURCENAMEPREFIX} "${JQ_FILTER}" main.json >> modified-template.json