---
title: The Bicep deployer function
type: post
tags:
- Development
- IaC
- Bicep
- Azure
date: 2025-01-08 01:00:00.000000000 +01:00
permalink: /2025/01/bicep-deployer-function
categories:
- Bicep
status: publish
---

Bicep evolves weekly, and with every release, new functionality is added. With the release of [v0.32.4](https://github.com/Azure/bicep/releases/tag/v0.32.4), the last release of 2024, a cool new function was added.

## deployer function

This newly added function helps get information about who is deploying the resources to the platform. This can, for example, help if there is a process within your organization to tag the resources with the person who deploys them.

Let's look at an example by outputting the object retrieved by the deployer function.

```yml
output deployer object = deployer()
```

![Bicep output deployer function](/assets/images/2025/deployer-output.png)

```json
{
  "objectId":"f275e010-27ad-4b3b-8c33-e9aac30fded4",
  "tenantId":"324f7296-1869-4489-b11e-912351f38ead"
}
```

As visible in the snippet above, this function returns the object id and the tenant id of the deploying principal. This information can then be used in other scenarios, like setting permissions or tagging resources. The snippet below shows the option of giving the deployer access to a resource group.

```yml
var principalId = deployer().objectId 

resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, contributorRoleDefinition.id)
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
```

Having the information available during deployment time and not having to retrieve it separately before the execution and supplying it as a parameter helps a lot and can help in situations where:

- You need access to a newly deployed KeyVault with RBAC permissions configured, and also want to deploy secrets.
- Using the same identity for your deployment scripts.

## Conclusion

The deployer function is a great new addition to the Bicep language and will help make advanced deployments much easier.

- [Bicep deployment functions](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-deployment?WT.mc_id=AZ-MVP-5004255)
- [Bicep code in my GitHub Repository](https://github.com/maikvandergaag/msft-bicep/tree/main/examples/deployment)
