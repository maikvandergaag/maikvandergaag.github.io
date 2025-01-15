---
title: A Bicep linting action for GitHub
type: post
tags:
- Development
- IaC
- Bicep
- Azure
- GitHub
date: 2025-01-14 01:00:00.000000000 +01:00
permalink: /2025/01/bicep-linting-action
categories:
- Bicep
status: publish
---

As Infrastructure as Code (IaC) practices continue to evolve, maintaining clean and error-free code is crucial for seamless deployments. For this process, I have been working on a composite action that I could use to scan my own Bicep files.

After having a first version and finding some shortcomings in the implementation:

- It constantly scans all files within the repository.
- When setting the output for the bicep linter to SARIF, I get a SARIF file for each file I scan.

This made me make a new version in which these shortcomings are fixed, and you can adjust the behavior based on input parameters. This ended in the composite action below.

```yml
name: "Bicep Linting"
description: "Composite action for running Bicep Linting."
branding:
  icon: 'code'
  color: 'blue'
inputs:
  allfiles:
    type: boolean
    description: 'Check all files or only the changed files'
    default: false
  create-sarif:
    description: 'Create a combined SARIF file'
    type: boolean
    default: true
  markdown-report:
    description: 'Create a markdown report'
    type: boolean
    default: false
  sarif-output-path:
    description: 'The file path to save the SARIF file'
    type: string
    default: 'bicep-lint.sarif'
  markdown-output-path:
    description: 'The file path to save the markdown report'
    type: string
    default: 'bicep-lint.md'
runs:
  using: "composite"
  steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 2
      - name: Get files
        shell: pwsh
        run: |
          $allFiles = [System.Convert]::ToBoolean("${{ inputs.allfiles }}")
          ${{ github.action_path }}\Get-BicepFiles.ps1 -AllFiles $allFiles
      - name: "Linting the bicep files"
        run: |
          $sarif = [System.Convert]::ToBoolean("${{ inputs.create-sarif }}")
          $markdown = [System.Convert]::ToBoolean("${{ inputs.markdown-report }}")
          ${{ github.action_path }}\Get-BicepLintingResults.ps1 -BicepFilesJson ${{ env.BICEP_FILES }} `
                     -CreateSarif $sarif `
                     -MarkdownReport $markdown `
                     -SarifOutputPath ${{ inputs.sarif-output-path }} `
                     -MarkdownOutputPath ${{ inputs.markdown-output-path }}
        shell: pwsh
```

The action makes sure that the fetch dept of the repository is 2. This way, the action is able to retrieve the changed files. This happens in the step 'Get files. ' The files it finds in this step are saved within an environment variable. Based on the input parameters, it will save the changed file or all the bicep files it can find.

The second step, 'Linting the bicep files,' will iterate through all the files and perform the 'bicep lint' command for each one. The command can optionally output to SARIF when the 'create-sarif' input parameter is set. It will combine the files into one large SARIF file.

As this was a personal project and I was also interested in how actions end up within the GitHub Marketplace, I published the action to the GitHub Marketplace for everyone to use. The action can be found [here](https://github.com/marketplace/actions/bicep-linting).

### Key Features

1. **Scan Only Changed Files**: This feature allows the action to lint only the modified files, saving time and resources by not re-linting unchanged files.

2. **Combine SARIF Output**: The action can combine the SARIF (Static Analysis Results Interchange Format) output from the Bicep linter into a single file. This makes integrating with GitHub's code scanning alerts easier and provides a comprehensive view of all linting issues.

3. **Markdown Reporting**: One of the most exciting features is the ability to display the linting results in the GitHub Actions Step Summary. This provides a clear and concise report directly within the GitHub interface, making it easy to review and address issues.

### How It Works

The Bicep Linting Action leverages the Bicep linter to analyze your Bicep files for potential issues. The results are then processed and presented in a user-friendly format. Here's a brief overview of how to set up and use the action in your GitHub workflows:

1. **Setup the Action**: Add the Bicep Linting Action to your workflow file.
2. **Configure the Inputs**: Specify the paths to your Bicep files and any additional options you want to use.
3. **Run the Workflow**: Trigger the workflow to lint your Bicep files and view the results in the GitHub Actions tab.

### Example Workflow

Below is an example of how to integrate the Bicep Linting Action into your GitHub workflow:

```yml
name: Lint Bicep Files

on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v2

      - name: Run Bicep Linting
        uses: maikvandergaag/bicep-linting-action@v1
        with:
          files: '**/*.bicep'
          only-changed: true
          sarif-output: 'bicep-lint-results.sarif'
```

By using the GitHub events, you can also ensure that different types of scans (full / changed) are done on different events. The below example shows this by doing a full scan on a pull request when the target branch is the main branch. If this is not the case, it will only take the changes, for example, for simple commits.

```yml
name: Bicep Linting

on:
  push:
  pull_request:
  workflow_dispatch:

env:
  allFiles: ${{ github.event_name != 'pull_request' && true || ( github.base_ref == 'main' && true || false) }}

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: maikvandergaag/action-biceplint@main
        with:
          allfiles: ${{ env.allFiles }}
          create-sarif: true
          markdown-report: false
          sarif-output-path: bicep-lint.sarif
      - name: Upload SARIF file
        if: always()
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: bicep-lint.sarif
          category: bicep-linting
```

Doing full scans on pull requests can be a requirement, especially when you have a rule set 'use-recent-api-versions' to error, and you must check the files occasionally. So you could, for example, create a daily scan using this extension.

## Conclusion

The Bicep Linting GitHub Action is an incredibly personal project that can help maintain high-quality Bicep code. Focusing on changed files, combining SARIF outputs, and providing markdown reports streamlines the linting process and integrates seamlessly with your GitHub workflows. Try and experience the benefits of automated Bicep linting in your projects!

When you have feature requests or are having issues, please share these!

- [Github Bicep Linting Action](https://github.com/marketplace/actions/bicep-linting)
- [Linting Action repository](https://github.com/maikvandergaag/action-biceplint)
- [Issues](https://github.com/maikvandergaag/action-biceplint/issues)