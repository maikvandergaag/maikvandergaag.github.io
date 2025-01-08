---
title: Exploring the Bicep test framework
type: post
tags:
- Development
- IaC
- Bicep
- Azure
date: 2024-12-19 01:00:00.000000000 +01:00
permalink: /2024/12/exploring-bicep-test-framework
categories:
- Bicep
status: publish
---

As Infrastructure as Code (IaC) becomes increasingly integral to modern cloud deployments, ensuring the reliability and correctness of infrastructure code is essential. That is why the Bicep team is experimenting with a Test Framework for Bicep.

The Azure Bicep Test Framework is designed to facilitate the testing of Bicep files, providing a structured approach to validate your infrastructure code. This framework allows you to write tests that can verify your Bicep templates, ensuring that your deployments are reliable and consistent.

## Enable Experimental Features

To get started with the Test Framework enable the 'assertion' and 'testframework' experimental features by adding the below snippet to the ['bicep.config'](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-config?WT.mc_id=AZ-MVP-5004255) file.

```json
{
  "experimentalFeaturesEnabled": {
        "testFramework": true,
        "assertions": true
  }
}
```

## Simple test

We start by creating a simple test. In this test, a check is performed on a parameter supplied during the deployment phase. For this example, we use the bicep file below, which deploys a storage account.

```yml
metadata info = {
  title: 'Storage Account'
  description: 'Module for creating a storage account'
  version: '1.0.0'
  author: 'Maik van der Gaag'
}

@description('The name of the storageaccount will be in the format st[name][environment]')
param name string

@description('The location of the storageaccount')
param location string = resourceGroup().location

@description('The SKU of the storage account')
param storageSKU string = 'Standard_LRS'

@allowed([
  'tst'
  'acc'
  'prd'
  'dev'
])
@description('The environment were the service is deployed to (tst, acc, prd, dev)')
param environment string

var storageName = 'st${name}${environment}'

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  sku: {
    name: storageSKU
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

output storageAccountName string = storage.name
```

The tests need to be added to the sample. This is done by using the 'assert' keyword to validate the results. As you may expect, the assert keyword needs to resolve to 'true' to pass the test.

```yml
  assert nameHyphen = !contains(storageName, '-')
  assert containsEnv = contains(storageName, environment)
```

The assertions mentioned in the snippet check the name of the storage account on specific aspects. The first checks if there are no hyphens in the name, and the second checks if it contains the environment in the name.

With the assertions added to the bicep file, the tests need to be specified. You must create a new bicep file called 'test.bicep' and add the test keyword, as I have done in the snippet below.

```yml
test storageTest 'storageaccount.bicep' = {
  params: {
    name: 'test1'
    location: 'uksouth'
    environment: 'prd'
  }
}

test failStorage 'storageaccount.bicep' = {
  params: {
    name: 'test-2'
    location: 'northeurope'
    environment: 'prd'
  }
}
```

The tests can now be executed using the bicep cli test command.

```bash
bicep test '.\tests\test.bicep'
```

This will show the results of the tests.

![Bicep Test Result](/assets/images/2024/bicep-test-result.png)

## Taking it further

The above showed how to perform a simple test, but in some situations, you may use [user-defined-functions](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/user-defined-functions?WT.mc_id=AZ-MVP-5004255) within Bicep.

To start with user-defined functions, we create a separate file. In this file, we will add a function to retrieve a location abbreviation. This can, for example, be used when using naming conventions within Azure. For demonstration, we have shortened the function and all the abbreviations.

```yml
@export()
func getLocationAbbreviation(location string) string => getAbbreviationLocation()[location]

func getAbbreviationLocation() object => {
  northeurope: 'ne'
  westeurope: 'we'
  uksouth: 'uks'
}
```

The '@export()' decorator specifies that the function can be imported into another Bicep file. This function retrieves the abbreviation of the supplied location by looking it up in the selected object.

We also need a few new things in our storage account bicep file to make it work. For reference, the complete file is shared below:

```yml
  metadata info = {
    title: 'Storage Account'
    description: 'Module for creating a storage account'
    version: '1.0.0'
    author: 'Maik van der Gaag'
  }

  import { getLocationAbbreviation } from '../functions/naming.bicep'

  @description('The name of the storageaccount will be in the format st[name][environment]')
  param name string

  @description('The location of the storageaccount')
  param location string = resourceGroup().location

  @description('The SKU of the storage account')
  param storageSKU string = 'Standard_LRS'

  @allowed([
    'tst'
    'acc'
    'prd'
    'dev'
  ])
  @description('The environment were the service is beign deployed to (tst, acc, prd, dev)')
  param environment string

  var storageName  = 'st${name}${environment}${abbrev}'

  //Tests
  param expectedAbbreviation string = ''
  var abbrev = getLocationAbbreviation(location)

  assert nameHyphen = !contains(storageName, '-')
  assert containsEnv = contains(storageName, environment)
  assert containsLocation = abbrev == expectedAbbreviation

  resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
    name: storageName
    location: location
    sku: {
      name: storageSKU
    }
    kind: 'StorageV2'
    properties: {
      allowBlobPublicAccess: false
      minimumTlsVersion: 'TLS1_2'
      supportsHttpsTrafficOnly: true
    }
  }

  output storageAccountName string = storage.name
```

The function is imported in the snippet using this line 'import { getLocationAbbreviation } from '../functions/naming.bicep'. When it is imported, the function can be used.

To be able to perform the tests, we also added a parameter for the expected abbreviation, and next to that, we have a new assertion to check the abbreviation.

```yml
  var abbrev = getLocationAbbreviation(location)
  assert containsLocation = abbrev == expectedAbbreviation
```

The test file can now be updated to include the expected abbreviations.

```yml
test storageTest 'storageaccount.bicep' = {
  params: {
    name: 'test1'
    location: 'uksouth'
    environment: 'prd'
    expectedAbbreviation: 'uks'
  }
}

test failStorage 'storageaccount.bicep' = {
  params: {
    name: 'test-2'
    location: 'northeurope'
    environment: 'prd'
    expectedAbbreviation: 'we'
  }
}
```

The test can now be executed in the same way.

![Bicep Test Result](/assets/images/2024/bicep-test-result-2.png)

## Conclusion

The Bicep Experimental Test Framework looks like an excellent addition to Bicep. The experimental feature has been there for some time, so I hope we will see this landing in Bicep with upcoming releases. When you are looking for more information regarding the Test Framework, check out the below links:

- [Experimental Test Framework](https://github.com/Azure/bicep/issues/11967)
- [Bicep code in my GitHub Repository](https://github.com/maikvandergaag/msft-bicep/tree/main/tests)
