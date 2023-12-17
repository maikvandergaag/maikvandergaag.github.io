---
title: Getting started with deployment stacks
type: post
tags:
- Development
- Azure
- Deployment stacks
- Bicep
date: 2023-12-20 08:00:05.000000000 +02:00
permalink: /2023/12/getting-started-with-deployment-stacks/
categories:
- Azure
- Infrastructure as Code
status: publish
---

Since June this year there is a new functionality in public preview called deployment stacks. Deployment stacks, deployment stacks are a Azure resource that enables you to manage a group of Azure resource as one unit regardless of the scope where the resources are deployed.
Next to that it also give you some other capabilities.

## Why should you use deployment stacks

There can be numerous reasons to start deployment stacks below are some of the main reasons:

- Manage resources as a single unit that spound multiple resource groups.
- Prevent modifications on resources.

## Capabilities

Currently deployment stacks can be implemented and managed via PowerShell or CLI. Currently there is no option to manage them via the portal, but you have the option to view them, maybe you have noticed this already within the portal on the different scopes.

![Portal deployment stacks option](/assets/images/2023/deployment-stacks-portal.png)

Within PowerShell you have different commands to manage deployment stacks:

- [New-AzResourceGroupDeploymentStack](https://learn.microsoft.com/en-us/powershell/module/az.resources/new-azresourcegroupdeploymentstack?view=azps-11.0.0&WT.mc_id=AZ-MVP-5004255): This creates a new deployment stack on a Resource group, for this command we also have similar commands for the other scopes, [New-AzSubscriptionDeploymentStack](https://learn.microsoft.com/en-us/powershell/module/az.resources/new-azsubscriptiondeploymentstack?view=azps-11.0.0&WT.mc_id=AZ-MVP-5004255) and [New-AzManagmentGroupDeploymentStack](https://learn.microsoft.com/en-us/powershell/module/az.resources/new-azmanagementgroupdeploymentstack?view=azps-11.0.0&WT.mc_id=AZ-MVP-5004255).
- [Get-AzResourceGroupDeploymentStack](https://learn.microsoft.com/en-us/powershell/module/az.resources/get-azresourcegroupdeploymentstack?view=azps-11.0.0&WT.mc_id=AZ-MVP-5004255): This lists all the deployment stacks on the specified scope, for this command there are also different commands for the other scopes, [Get-AzSubscriptionDeploymentStack](https://learn.microsoft.com/en-us/powershell/module/az.resources/get-azsubscriptiondeploymentstack?view=azps-11.0.0&WT.mc_id=AZ-MVP-5004255) and [Get-AzManagementGroupDeploymentStack](https://learn.microsoft.com/en-us/powershell/module/az.resources/get-azmanagementgroupdeploymentstack?view=azps-11.0.0&WT.mc_id=AZ-MVP-5004255).
- [Set-AzResourceGroupDeploymentStack](https://learn.microsoft.com/en-us/powershell/module/az.resources/set-azresourcegroupdeploymentstack?view=azps-11.0.0&WT.mc_id=AZ-MVP-5004255): Updating a deployment stacks is done via this commando. For this command there are also different commmands for the other scopes, [Set-AzSubscriptionDeploymentStack](https://learn.microsoft.com/en-us/powershell/module/az.resources/set-azsubscriptiondeploymentstack?view=azps-11.0.0&WT.mc_id=AZ-MVP-5004255) and [Set-AzManagmentGroupDeploymentStack](https://learn.microsoft.com/en-us/powershell/module/az.resources/set-azmanagementgroupdeploymentstack?view=azps-11.0.0&WT.mc_id=AZ-MVP-5004255). Updating a deployment stacks with for example always needs to be done with the Set verb and not the New verb.
- [Remove-AzResourceGroupDeploymentStack](https://learn.microsoft.com/en-us/powershell/module/az.resources/remove-azresourcegroupdeploymentstack?view=azps-11.0.0&WT.mc_id=AZ-MVP-5004255): This will delete the deployment stack from the scope. For this command there are also different commands for the other scopes, [Remove-AzSubscriptionDeploymentStack](https://learn.microsoft.com/en-us/powershell/module/az.resources/remove-azsubscriptiondeploymentstack?view=azps-11.0.0&WT.mc_id=AZ-MVP-5004255) and [Remove-AzManagementGroupDeploymentStack](https://learn.microsoft.com/en-us/powershell/module/az.resources/remove-azmanagementgroupdeploymentstack?view=azps-11.0.0&WT.mc_id=AZ-MVP-5004255). Not specifing a delete switch will detach the managed resources if your would also like to delete the resources a specific delete flag needs to be specified (DeleteAll, DeleteResourceGroup, DeleteResource)

When looking into the functions for creating and updating deployment stacks you may have noticed that you can add a DenySettingsMode with a couple of other settings, these settings are referred to as deny settings. The following options can be configured:

- DenySettingsMode: Specifies the actions that can not be performed. This restriction applies to everyone unless explicitly granted access. The values include: None, DenyDelete, and DenyWriteAndDelete.
- DenySettingsApplyToChildScopes: Deny settings are applied to nested resources under managed resources.
- DenySettingsExcludedAction: List of role-based management operations that are excluded from the deny settings. You can add a list of 200 actions an example could be 'Microsoft.Compute/virtualMachines/write Microsoft.StorageAccounts/delete'.
- DenySettingsExcludedPrincipal: List of Microsoft Entra principal IDs excluded from the lock. Up to five principals are permitted.

If you look into these deny settings you may have noticed that these settings gives us a great value for a specific case i have been asked a lot of times. Imagine that you have a strict environment were you are able to deploy resources with for example a managed identity by you are not allowed to update the resources and also want to prevent changes made in manual ways.
Using the existing RBAC options does not really give an option as due to the inheritance capabilities this was hard to handle. By using deployment stacks you have the option of setting a DennySettingMode to 'DenyWriteAndDelete' and adding the managed identity to the DenySettingsExcludedPrincipal option. This will make sure that nobody but the managed identity is able to alter the resources.

> Deployment stacks requires Azure PowerShell version 10.1.0 or later or Azure CLI version 2.50.0 or later.

## Getting started

To get started with deployment stacks you need to start by created a bicep file that deploys your resources. For this article we will deploy two resources group in which we will deploy two storage accounts.

> A deployment stacks says something about your resources and not your resource groups. So make sure all resource groups are there before deploying your stack.

```yaml
targetScope = 'subscription'

param location string = 'westeurope' 


module str1 'storageaccount.bicep' = {
  name: 'deployment-str1'
  scope: resourceGroup('sponsor-rg-rg1')
  params: {
    name: 'stackstr1'
    location: location
  }
}

module str2 'storageaccount.bicep' = {
  name: 'deployment-str2'
  scope: resourceGroup('sponsor-rg-rg2')
  params: {
    name: 'stackstr2'
    location: location
  }
}
```
As you can see this is a very simple bicep file that deploys two resource groups with in both a storage account. For the storgae account we make use of a very simple module that is displayed below.

> At the time of writing this article you are not able to use a function like 'deployment().location' to retrieve the deployment location. The deployment of the stack isn't also visible in the deployment section of the portal.

```yaml
param location string = resourceGroup().location

param name string

resource str 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: toLower('str${name}')
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

output storageAccountName string = str.name
output storageAccountResourceId string = str.id
```

### Deploying the stack

To deploy the stack we will use the function with the 'New' verbs and as we are deploying to a subscription we will use the function 'New-AzSubscriptionDeploymentStack'

```posh
New-AzResourceGroup -Name "sponsor-rg-stacks" -Location "westeurope"
New-AzResourceGroup -Name "sponsor-rg-rg1" -Location "westeurope"
New-AzResourceGroup -Name "sponsor-rg-rg2" -Location "westeurope"

New-AzSubscriptionDeploymentStack `
  -Name "stack-demo-01" `
  -Location "westeurope" `
  -TemplateFile ".\main.bicep" `
  -DeploymentResourceGroupName "sponsor-rg-stacks" `
  -DenySettingsMode "none"
```

The resource group we have specified in the 'DeploymentResourceGroupName' is the group were the deployment stacks resource will be deployed to. At the time of writing this looks like a simple pointer for the deployment because in the portal there isn't any specific resource in the resource group.

![Deployment stacks resource group](/assets/images/2023/deployment-stacks-rg.png)

But if we look under the deployment stacks option we see our newly created stack.

![Overview stacks](/assets/images/2023/deployment-stacks-overview.png)

### Updating the stack

When you for example want to update your stack by adding an additional resource, this resource needs to be added in de bicep file.

```yaml
targetScope = 'subscription'

param location string = 'westeurope' 

module str1 'storageaccount.bicep' = {
  name: 'deployment-str1'
  scope: resourceGroup('sponsor-rg-rg1')
  params: {
    name: 'stackstr1'
    location: location
  }
}

module str2 'storageaccount.bicep' = {
  name: 'deployment-str2'
  scope: resourceGroup('sponsor-rg-rg2')
  params: {
    name: 'stackstr2'
    location: location
  }
}

module str3 'storageaccount.bicep' = {
  name: 'deployment-str3'
  scope: resourceGroup('sponsor-rg-rg2')
  params: {
    name: 'stackstr3'
    location: location
  }
}
```

When the bicep is updated when can update the deployment stack.

```posh
Set-AzSubscriptionDeploymentStack `
  -Name "stack-demo-01" `
  -Location "westeurope" `
  -TemplateFile ".\main.bicep" `
  -DeploymentResourceGroupName "sponsor-rg-stacks" `
  -DenySettingsMode "none"
```

## Conclusion

I hope this article gave you some insights on what deployment stacks can do for you. Please note that this service is still in preview and is subject to change. If you want to learn more keep an eye out on my blog and check the below resources.

- [Blog Source Code](https://github.com/maikvandergaag/msft-deploymentstacks)
- [Deployment stacks (Preview)](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-stacks?tabs=azure-powershell&WT.mc_id=AZ-MVP-5004255)
- [Quickstart: Create and deploy a deployment stack with Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/quickstart-create-deployment-stacks?tabs=azure-cli%2CCLI&WT.mc_id=AZ-MVP-5004255)