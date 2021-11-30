param serviceBusNamespace string
param location string

resource servicebus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' = {
  name: serviceBusNamespace
  location: location
}

resource servicebus_authrule 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2021-06-01-preview' existing = {
  name: 'RootManageSharedAccessKey'
  parent: servicebus
}

resource topic 'Microsoft.ServiceBus/namespaces/topics@2021-06-01-preview' = {
  name: 'speedingviolations'
  parent: servicebus
}

output servicebus_connection_string string = listKeys(servicebus_authrule.id, servicebus_authrule.apiVersion).primaryConnectionString
