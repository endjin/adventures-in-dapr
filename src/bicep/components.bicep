param keyVaultName string
param keyVaultAccessObjectId string
param serviceBusNamespace string
param serviceBusConnectionStringSecretName string
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

resource keyvault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [
      {
        objectId: keyVaultAccessObjectId
        permissions: {
          secrets: [
            'get'
          ]
        }
        tenantId: tenant().tenantId
      }
    ]
    tenantId: tenant().tenantId
  }
}

resource connection_string_secret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: serviceBusConnectionStringSecretName
  parent: keyvault
  properties: {
    contentType: 'text/plain'
    value: listKeys(servicebus_authrule.id, servicebus_authrule.apiVersion).primaryConnectionString
  }
}

output keyVaultUri string = keyvault.properties.vaultUri
output keyVaultName string = keyvault.name
output serviceBusConnectionStringSecretUri string = connection_string_secret.properties.secretUri
