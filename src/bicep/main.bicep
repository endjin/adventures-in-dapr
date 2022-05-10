@description('The target Azure location for all resources')
param location string
@description('A string that will be prepended to all resource names')
param prefix string
@description('The key vault secret name containing the service bus connection string')
param serviceBusConnectionStringSecretName string = 'ServiceBus-ConnectionString'
@description('The ObjectId of the service principal that will be granted key vault access')
param keyVaultAccessObjectId string
param timestamp string = utcNow()


var rgName = '${prefix}-adventures-in-dapr'
var serviceBusNamespace = '${prefix}-aind-namespace'
var keyVaultName = '${prefix}aindkv'


targetScope = 'subscription'


resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

module components 'components.bicep' = {
  name: 'aind-components-deploy-${timestamp}'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    serviceBusNamespace: serviceBusNamespace
    keyVaultName: keyVaultName
    keyVaultAccessObjectId: keyVaultAccessObjectId
    serviceBusConnectionStringSecretName: serviceBusConnectionStringSecretName
  }
}


output keyVaultName string = components.outputs.keyVaultName
output keyVaultSecretName string = serviceBusConnectionStringSecretName
output serviceBusConnectionStringSecretUri string = components.outputs.serviceBusConnectionStringSecretUri
