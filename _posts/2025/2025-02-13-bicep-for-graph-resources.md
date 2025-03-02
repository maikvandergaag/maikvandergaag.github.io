---
title: Bicep for graph resources
type: post
tags:
- Development
- IaC
- Bicep
- Azure
- Graph
- GitHub
date: 2025-02-13 01:00:00.000000000 +01:00
permalink: /2025/01/bicep-for-graph-resources
categories:
- Bicep
status: publish
header:
  og_image: /assets/images/2025/graph-extension.png
---

For the Bicep language, an extensibility framework exists that adds capabilities to extend Infrastructure as Code deployments to other resources and providers. The extensibility framework is still an experimental feature, so it is subject to change and needs to be enabled separately.

Add the following snippet to your Bicep configuration file (bicepconfig.json) to enable this experimental feature.

```json
    "experimentalFeaturesEnabled": {
        "extensibility": true
    }
```

At the moment of writing this blog post there is support for the Microsoft Graph and Kubernetes.

Using the Graph extension for Bicep allows you to deploy and change a limited set of Entra objects (at the moment of writing). The objects that can be authored at the moment of writing are:

- Applications
- App role assignments
- Federated identity assignment
- Groups
- OAuth2 Permission grants
- Service Principals
- Users

![Graph Extension](/assets/images/2025/graph-extension.png)

As you might expect, the extension would call the Graph API from the machine where the deployment is executed. But the Bicep extension works a little bit differently.

As with the regular Bicep files without the extensions, the file is built into a JSON-represented format (locally). As you can see in the above image, this file is then sent to the Azure Resource Manager. The deployment agent then decides whether to send the resources to the Azure Resource Manager or the Graph API for the Graph resources.

To use the graph resources, you need to do two things. The extension alias needs to be configured within the 'bicepconfig.json.'

```json
    "extensions": {
      "microsoftGraphV1": "br:mcr.microsoft.com/bicep/extensions/microsoftgraph/v1.0:0.1.9-preview"
    }
```

'microsoftGraphV1' is the alias that needs to be used and included in the template file. To use the resources within that file, include the following line.

```yml
extension microsoftGraphV1
```

With all of this setup, the Graph objects can be specified. When using Visual Studio Code, the Bicep extension also has intelligence to get you started.

![IntelliSense](/assets/images/2025/bicep-extension.png)

For this blog post, we will create an Entra group, add members and owners, and give that group permission on an Azure resource.
Adding members and owners to a group normally uses the users' IDs. However, as we want to parameterize the file so that other people can use it, we will have to retrieve the users' IDs using their UPN.

```yml
param location string = resourceGroup().location

param members array = []

param owners array = []

param name string = 'default'

var readerRole = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'

var roleAssignmentName = guid(resourceGroup().id, groupName, storageName)

var groupName = 'sg-${name}'

var storageName = 'stgraphtest${name}'
```

This first section shows the parameters and variables we will use during the deployment. As you can see, there is an owners and members array, which specifies the users' UPNs.
The other variables and parameters specify the name and role we will use during the deployment.

The second part is the logic that will be used to retrieve the IDs of the owners and members based on their UPN. As mentioned above, you need to supply their IDs to add members and owners to the group.

```yml
resource ownerList 'Microsoft.Graph/users@v1.0' existing = [for upn in owners: {
  userPrincipalName: upn
}]

resource memberList 'Microsoft.Graph/users@v1.0' existing = [for upn in members: {
  userPrincipalName: upn
}]
```

The group can be created with the users' information. The snippet below shows that the owners and members have been added, and the group name has been specified.

```yml
resource readerGroup 'Microsoft.Graph/groups@v1.0' = {
  displayName: groupName
  mailEnabled: false
  mailNickname: uniqueString(groupName)
  securityEnabled: true
  uniqueName: groupName
  owners: [for i in range(0, length(owners)): ownerList[i].id]
  members: [for i in range(0, length(members)): memberList[i].id]
}
```

The other parts needed for this deployment are just regular Bicep / Azure deployment of resources.

```yml
resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties:{
    minimumTlsVersion: 'TLS1_2'
  }
}

resource readersRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storage
  name: roleAssignmentName
  properties: {
    principalId: readerGroup.id
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', readerRole)
  }
}
```

As you can see in the above snippet, a storage account is created, and a role is assigned to the security group we previously added.

All of this together creates the following deployment file.

```yml
extension microsoftGraphV1

param location string = resourceGroup().location

param owners array = []
param members array = []

param name string = 'default'

var readerRole = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'

var roleAssignmentName = guid(resourceGroup().id, groupName, storageName)

var groupName = 'sg-${name}'

var storageName = 'stgraphtest${name}'

resource ownerList 'Microsoft.Graph/users@v1.0' existing = [for upn in owners: {
  userPrincipalName: upn
}]

resource memberList 'Microsoft.Graph/users@v1.0' existing = [for upn in members: {
  userPrincipalName: upn
}]

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties:{
    minimumTlsVersion: 'TLS1_2'
  }
}

resource readerGroup 'Microsoft.Graph/groups@v1.0' = {
  displayName: groupName
  mailEnabled: false
  mailNickname: uniqueString(groupName)
  securityEnabled: true
  uniqueName: groupName
  owners: [for i in range(0, length(owners)): ownerList[i].id]
  members: [for i in range(0, length(owners)): memberList[i].id]
}

resource readersRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storage
  name: roleAssignmentName
  properties: {
    principalId: readerGroup.id
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', readerRole)
  }
}
```

As you can see, the extension model makes it very easy to create more advanced deployments by including the capabilities for Entra objects. For the deployment above, the parameter file could look like this.

```yml
using './main.bicep'

param owners = ['maik@msftplayground.info' ]
param members = [ 'piet@msftplayground.info'
 'charlotte@msftplayground.info'
]
param name = 'graph-group-name'

```

It would be great if, over time, many other graph objects are added to the extension so that we could also author SharePoint sites or other M365 / Entra objects.

If you want to learn more about the Graph extension or Bicep, you can have a look at the following resources:

- [msft-bicep](https://github.com/maikvandergaag/msft-bicep) - My personal bicep repository that contains a lot of bicep samples and also includes examples regarding the graph extension.
- [Bicep templates for Microsoft Graph](https://learn.microsoft.com/en-us/graph/templates/?WT.mc_id=AZ-MVP-5004255) - The official Microsoft learn documentation regarding the Graph extension for Bicep.
