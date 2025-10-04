---
title: Power Up Your Infrastructure with Bicep Extensions
type: post
tags:
- Bicep
- Extensions
- Local
- Preview
date: 2025-09-01 01:00:00.000000000 +01:00
permalink: /2025/09/bicep-extensions
categories:
- Azure
status: publish
header:
  og_image: /assets/images/2025/bicep-extensions.png
---

Bicep was initially developed to enhance ARM. Know it is also possible to reference resources beyond the scope of the Azure Resource Manager. As you may know, it is now possible to deploy resources within a Kubernetes platform and make use of the Microsoft Graph.

* [Use Bicep Extensions](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-extension?WT.mc_id=AZ-MVP-5004255)
* [Bicep Graph Extension](https://learn.microsoft.com/en-us/graph/templates/?WT.mc_id=AZ-MVP-5004255)
* [Bicep Kubernetes Extension](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-kubernetes-extension?WT.mc_id=AZ-MVP-5004255)

These extensions are really great and make Bicep much more powerful than it already is. However, what if I tell you that the way this is built also has its shortcomings?

## Disadvantage Bicep Extensions

At the time of writing this article, Bicep extensions have one main disadvantage. Let me explain, take a close look at the image below.

![Bicep Extension Process](/assets/images/2025/bicep-extensions.png)

As you may have seen in the image, the Bicep templates that you create locally are sent to the Azure Resource Manager API, where the deployment engine determines whether the Azure Resource Manager should perform its work or, in this example, the resources should be created by the Graph API. As this is all server-side (@Microsoft), there is no really good way for the community to jump in and help build extensions, unlike with Terraform, which makes the improvements and new additions to the extensions take a very long time.
But wait, there are some cool things in preview.

## Bicep Local

Since a couple of months Bicep contains a preview feature called “localDeploy”. When activated, you can initiate the deployment from your local device and add extensions.

Currently, the community has already developed some nice extensions that you can use and try out:

* [Bicep GitHub Extensions - Anthony Martin (Microsoft)](https://github.com/anthony-c-martin/bicep-ext-github)
* [Key Vault Extension - Anthony Martin (Microsoft)](https://github.com/anthony-c-martin/bicep-ext-keyvault)
* [Azure Databricks extension - Gijs Reijn](https://github.com/Gijsreyn/bicep-ext-databricks)
* [Http Extension - Maik van der Gaag](https://github.com/maikvandergaag/bicep-ext-http)

As you can imagine, and as you may have seen on the list of extensions, you can create your own. Since version 0.37.4 of Bicep, there has been documentation released to get started creating your own extensions:

* [Creating a Local Extension with .Net](https://github.com/Azure/bicep/blob/main/docs/experimental/local-deploy-dotnet-quickstart.md)

## Start Testing Bicep Local deployments

To get started deploying with local deployments, a few steps need to be taken. For these steps, we use the repository below as a reference.

* [Bicep Local Repository](https://github.com/maikvandergaag/msft-bicep-local)

In that repository, you can find multiple samples of doing local deployments. With the steps and configurations below, you can get started using this extraordinary capability.

1. Make sure that you have one of the latest Bicep installations.
2. Add the “localDeploy” experimental feature to your bicepconfig.json file.

```json
  "experimentalFeaturesEnabled": {
    "localDeploy": true
  }
```

{:start="3"}
3. When using the CLI you can deploy locally by using the "bicep local" command.

```bash
Bicep local main.bicepparam
```

The deployments can also be run from Visual Studio Code. To do it from Visual Studio code open the deployments pane. You can do this while the bicepparam file is open.

![Bicep Deployment Pane Button](/assets/images/2025/deployment-pane-button.png)

From the pane that opens, deploy the Bicep file and see the output of your local deployment.

![Bicep Deployment Pane](/assets/images/2025/deploymentpane.png)

### Tracing

When you have problems during your local deployments, which I have encountered occacionally you can enable tracing to get more insights. This is done by setting the Bicep Tracing environment variable.

#### cmd

```bash
set BICEP_TRACING_ENABLED=true
```

#### PowerShell

```powershell
$env:BICEP_TRACING_ENABLED=$true
```

## Conclusion

Local deploy is a great extension to Bicep that helps you get started with different platforms or enables more on the data plane. So let's hope this functionality will be further developed and that it will become generally available.

Be sure to look out for my next blog post, where I'll delve deeper into the extension I have developed.
