targetScope='subscription'

param subscriptionId string = '58ac7037-efcc-4fb6-800d-da6ca2ee6aed'
param storageAccountName string = 'kamilopssa4'

module newRG 'modules/rg.bicep' = {
  name: 'newResourceGroup'
  scope: subscription(subscriptionId)
  params: {
    resourceGroupName: 'kamilm-bicep3-rg'
    resourceGroupLocation: 'westeurope'
  }
}
