---
title: Verified commits in GitHub
type: post
tags:
- Development
- Github
- Git
date: 2023-12-09 08:33:30.000000000 +02:00
permalink: /2023/12/verified-commits-in-github/
categories:
- Git
- Development
status: draft
---

Git commits can be signed by using a GPG key. With this GPG key you can prove that a specific commits comes from you, doing this will also add a 'Verified' badge next to your commit.

![]({{ site.baseurl }}assets/images/2023/github-verified.png)

By signing your commits you  prove that the commit actually came from you as it is very easy to add anyone as an author by adding the '--author' flag. By following the below steps we will make sure that we sign our commits.

dd