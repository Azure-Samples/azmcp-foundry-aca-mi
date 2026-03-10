/*
  This template creates an Entra (Azure AD) application with the necessary components
  for secure authentication and authorization in Azure.

  What gets created:

  Entra Application Registration
     This is like a "blueprint" that defines what the Entra App can do. It includes
     app roles (think of these as custom permissions), identifier URIs for OAuth validation,
     and basic app configuration.

  Service Principal
     This is the actual "identity" that represents the Entra App within the Azure
     tenant. This is what you'll assign Azure permissions to, not the app registration itself.
  
  The Entra App registration defines what the app could do, while the Service Principal
  defines what it can actually do in your specific environment.
*/

extension microsoftGraphV1

@description('Display name for the Entra Application')
param entraAppDisplayName string

@description('Unique name for the Entra Application')
param entraAppUniqueName string

@description('Service Management Reference for the Entra Application. Optional GUID used to link the app to a service in Azure.')
param serviceManagementReference string = ''

var entraAppRoleValue = 'Mcp.Tools.ReadWrite.All'
var entraAppRoleId = guid(subscription().id, entraAppRoleValue)
var entraAppRoleDisplayName = 'Azure MCP Tools ReadWrite All'
var entraAppRoleDescription = 'Application permission for Azure MCP tool calls'

var entraAppScopeValue = 'Mcp.Tools.ReadWrite'
var entraAppScopeId = guid(subscription().id, entraAppScopeValue)
var entraAppScopeDisplayName = 'Azure MCP Tools ReadWrite'
var entraAppScopeDescription = 'Delegated permission for Azure MCP tool calls'

// VS Code client app ID for pre-authorization
var vsCodeClientAppId = 'aebc6443-996d-45c2-90f0-388ff96faa56'

resource entraApp 'Microsoft.Graph/applications@v1.0' = {
  uniqueName: entraAppUniqueName 
  displayName: entraAppDisplayName
  serviceManagementReference: !empty(serviceManagementReference) ? serviceManagementReference : null
  appRoles: [
    {
      id: entraAppRoleId
      displayName: entraAppRoleDisplayName
      description: entraAppRoleDescription
      value: entraAppRoleValue
      isEnabled: true
      allowedMemberTypes: ['Application']
    }
  ]
  api: {
    requestedAccessTokenVersion: 2
    oauth2PermissionScopes: [
      {
        id: entraAppScopeId
        value: entraAppScopeValue
        type: 'User'
        adminConsentDisplayName: entraAppScopeDisplayName
        adminConsentDescription: entraAppScopeDescription
        userConsentDisplayName: entraAppScopeDisplayName
        userConsentDescription: entraAppScopeDescription
        isEnabled: true
      }
    ]
  }
}

resource entraAppUpdate 'Microsoft.Graph/applications@v1.0' = {
  uniqueName: entraAppUniqueName
  displayName: entraAppDisplayName
  serviceManagementReference: !empty(serviceManagementReference) ? serviceManagementReference : null
  appRoles: entraApp.appRoles
  identifierUris: ['api://${entraApp.appId}']
  api: {
    requestedAccessTokenVersion: 2
    oauth2PermissionScopes: entraApp.api.oauth2PermissionScopes
    preAuthorizedApplications: [
      {
        appId: vsCodeClientAppId
        delegatedPermissionIds: [entraAppScopeId]
      }
    ]
  }
}

resource entraServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: entraApp.appId
}

output entraAppClientId string = entraApp.appId
output entraAppObjectId string = entraApp.id
output entraAppIdentifierUri string = 'api://${entraApp.appId}'
output entraAppRoleValue string = entraAppRoleValue
output entraAppRoleId string = entraApp.appRoles[0].id
output entraAppServicePrincipalObjectId string = entraServicePrincipal.id
