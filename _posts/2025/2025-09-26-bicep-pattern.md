---
title: Bicep pattern paramter
type: post
tags:
- Bicep
- Parameter
- pattern
date: 2025-09-26 01:00:00.000000000 +01:00
permalink: /2025/09/bicep-pattern-paramater
categories:
- IaC
status: publish
header:
  og_image: /assets/images/2025/bicep-pattern.png
---

On numerous occasions, I observed that this was not widely known; however, when working with the Bicep CLI, several commands (such as build or lint) support a --pattern parameter.

With this parameter, you can target multiple files by specifying a specific file-matching pattern. Some use cases to use this are:

* Bulk building Bicep files.
* Validating all the Bicep files (lint) in a repository. (modules)

As mentioned, the option is used to specify file-matching patterns, allowing you to target multiple files in one command without manually listing them all. The parameter accepts standard patterns (similar to those used in shells or file systems). This makes it very useful for automating builds or validations across a whole repository of Bicep templates.

## Pattern

The pattern is a simple string-matching syntax used to select files and folders based on wildcards. In the Bicep CLI, patterns let you target multiple files without listing them individually.

* &ast; → matches any number of characters (except /).
* ** → matches any number of subdirectories.

## Examples

Validate all bicep files found in all subfolders.

```bicep
bicep lint --pattern  "./**/*.bicep
```

Build all bicep files in the current directory.

```bicep
bicep build --pattern  "./*.bicep
```