#!/usr/bin/env bash


sed -i.bu 's/defaultResourceNamePrefix string/defaultResourceNamePrefix string = \'${PREFIX}\'/g' src/arm/main.bicep

#jq --arg PREFIX ${DEFAULTRESOURCENAMEPREFIX} --arg STORAGE ${STORAGEACCOUNTNAME} --arg COSACCNAME ${COSMOSACCOUNTNAME} --arg COSCOLLNAME ${COSMOSCOLLECTIONNAME} --arg COSDBNAME ${COSMOSDATABASENAME} --arg APPINS ${APPLICATIONINSIGHTSNAME} --arg FUNCNAME ${FUNCTIONAPPNAME} --arg WEBAPPNAME ${WEBAPPNAME} "${JQ_FILTER}" src/arm/azuredeploy.parameters.json >> src/arm/modified-parameters.json