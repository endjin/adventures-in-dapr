param keyVaultName string
param keyVaultAccessObjectId string
param serviceBusNamespace string
param serviceBusConnectionStringSecretName string
param storageAccountAccessKeySecretName string
param storageAccountName string
param entryCamQueueName string
param exitCamQueueName string
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

resource storage_account 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource storage_queues 'Microsoft.Storage/storageAccounts/queueServices@2021-09-01' = {
  name: 'default'
  parent: storage_account
}

resource entrycam_queue 'Microsoft.Storage/storageAccounts/queueServices/queues@2021-09-01' = {
  name: entryCamQueueName
  parent: storage_queues
}

resource exitcam_queue 'Microsoft.Storage/storageAccounts/queueServices/queues@2021-09-01' = {
  name: exitCamQueueName
  parent: storage_queues
}

resource storage_access_key_secret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: storageAccountAccessKeySecretName
  parent: keyvault
  properties: {
    contentType: 'text/plain'
    value: listKeys(storage_account.id, storage_account.apiVersion).keys[0].value
  }
}

output keyVaultUri string = keyvault.properties.vaultUri
output keyVaultName string = keyvault.name
output serviceBusConnectionStringSecretUri string = connection_string_secret.properties.secretUri
output storageAccountAccessKeySecretUri string = storage_access_key_secret.properties.secretUri
