@description('The target Azure location for all resources')
param location string
@description('A string that will be prepended to all resource names')
param prefix string


var rgName = '${prefix}-adventures-in-dapr'
var serviceBusNamespace = '${prefix}-aind-namespace'


targetScope = 'subscription'


resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

module components 'components.bicep' = {
  name: 'aind-components-deploy'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    serviceBusNamespace: serviceBusNamespace
  }
}


output servicebus_connection_string string = components.outputs.servicebus_connection_string


