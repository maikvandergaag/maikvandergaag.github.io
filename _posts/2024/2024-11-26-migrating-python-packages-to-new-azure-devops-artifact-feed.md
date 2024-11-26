---
title: Migrating Python packages to new Azure DevOps Artifact Feed
type: post
tags:
- Development
- Azure DevOps
- 
- PowerShell
date: 2024-11-26 01:00:00.000000000 +01:00
permalink: /2024/11/migrating-python-packages-to-new -azure-devops-artifact-feed
categories:
- Azure DevOps
status: publish
---

It has been almost a year since I last wrote a blog post. Life can sometimes throw unexpected challenges our way, and for various reasons—mostly on the personal front—I found myself unable to dedicate the time or energy to keep writing. But now, I’m excited to pick up the habit again and share some of the interesting things I’ve been working on!  

## Background  

In one of my recent projects, we needed to set up a new [**Artifact Feed**](https://learn.microsoft.com/en-us/azure/devops/artifacts/concepts/feeds?view=azure-devops&WT.mc_id=AZ-MVP-5004255) within Azure DevOps. The project centers around building a **Software Development Platform** to support multiple internal communities while working with **GitHub Enterprise**. Unfortunately, **GitHub Packages** did not fully meet the client’s requirements as it does not support python packages.  

Given that the client was already using Azure DevOps, we decided to leverage Azure Artifacts for our python package management. One of the standout features of Azure Artifacts is its ability to integrate seamlessly with **Microsoft Entra (Azure AD)**, enabling us to make the feed accessible to anyone within the tenant without to much effort.

## The Challenge  

As part of this setup, we needed to migrate our existing feed into an organizational feed within Azure Artifacts. This presented a few challenges:  
1. **Feed Size:** The existing feed contained a large number of packages, making a manual migration impractical.  
2. **Pipeline Dependencies:** Updating all the existing pipelines manually to point to the new feed would have been time-consuming and error-prone.  

To address these challenges, we developed a script to automate the migration process.  

## What does it do 

The script automates the process of:  
1. **Downloading** packages from the old feed.  
2. Temporarily **storing** the packages locally.  
3. **Uploading** the packages to the new organizational feed.  

## Key points of the script  

- Supports **Python package feeds**.  
- Facilitates migration from a **project feed** to an **organizational feed**.  
- Transfers packages along with all their versions.  


**Note:** Metadata is not preserved during the migration process; only the packages, their versions are moved and all information saved in the package itself. 

```powershell
param (
    [string]$organization,
    [string]$project,
    [string]$sourceFeed,
    [string]$destinationFeed,
    [string]$localFolder,
    [string]$pat
)

# Base64 encode the PAT
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)"))

# Function to get packages from a feed
function Get-Packages {
    param (
        [string]$feed
    )
    $url = "https://feeds.dev.azure.com/$organization/$project/_apis/packaging/feeds/$feed/packages?api-version=6.0-preview.1&includeAllVersions=true"
    $response = Invoke-RestMethod -Uri $url -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
    return $response.value
}

# Function to download all package files including their versions from a feed
function Get-PackagesFiles {
    param (
        [string]$feed,
        [string]$destinationFolder
    )

    $feedUri = "https://pkgs.dev.azure.com/$organization/$project/_packaging/$feed/pypi/simple/"
    $packages = Get-Packages -feed $feed

    foreach ($package in $packages) {
        foreach ($version in $package.versions) {
            $packageName = $package.normalizedName

            Write-Host "Downloading package: $packageName==$($version.version)" -ForegroundColor Green
            pip download "$packageName==$($version.version)" --no-deps --dest $destinationFolder --ignore-requires-python --index-url $feedUri
        }
    }
}

# Function to publish packages using twine
function Publish-Packages {
    param (
        [string]$sourceFolder,
        [string]$destination
    )

    $feed = "https://pkgs.dev.azure.com/$organization/_packaging/$destination/pypi/upload/"

    $twinePath = "twine"  # Ensure twine is installed and available in the PATH

    $packageFiles = Get-ChildItem -Path $sourceFolder

    foreach ($packageFile in $packageFiles) {
        $filePath = $packageFile.FullName

        Write-host "Publishing $filePath to $feed"
        & $twinePath upload --repository-url $feed -u x -p $pat $filePath 
    }
}

# Main script execution
Get-PackagesFiles -feed $sourceFeed -destinationFolder $localFolder
Publish-Packages -sourceFolder $localFolder -destination $destinationFeed

Write-Output "Packages have been successfully copied to the destination feed."
```

- [Script Repository](https://github.com/maikvandergaag/msft-scripts)
- [Azure Artifacts](https://learn.microsoft.com/en-us/azure/devops/artifacts/concepts/feeds?view=azure-devops&WT.mc_id=AZ-MVP-5004255)
- [Manaage Permissions Azure Artifacts Feed](https://learn.microsoft.com/en-us/azure/devops/artifacts/feeds/feed-permissions?view=azure-devops&WT.mc_id=AZ-MVP-5004255)