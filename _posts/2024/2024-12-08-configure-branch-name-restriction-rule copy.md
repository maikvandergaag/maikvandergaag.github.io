---
title: Configure branch name restriction rule
type: post
tags:
- Development
- GitHub
- Branches
date: 2024-12-08 01:00:00.000000000 +01:00
permalink: /2024/12/configure-branch-name-restriction-rule
categories:
- GitHub
status: publish
---

Many organizations and developers try to restrict the naming formats of the branches. This can be the case for multiple reasons.

In GitHub, this can be achieved very easily and can also be forced on an organizational level if needed. The steps below explain how to restrict the naming of branches for the whole organization, but the steps also apply when doing this for a repository.

## Restricting branch names

**1** - In GitHub, go to the settings for your organization.

**2** - Within the settings, click 'Repository' and then 'Rulesets'.

![GitHub Organization settings](/assets/images/2024/organization-settings.png)

**3** - Click on 'New ruleset' to create a new ruleset, and select 'new branch ruleset'.

![Branch ruleset](/assets/images/2024/branch-ruleset.png)

**4** - On the new page, give your rule set an appropriate name and set the 'Enforcement status' to 'Active' for your ruleset to work. Another good option is to set it to 'Evaluate'. This will help you test out your rule and gain insights before enforcing it.

![Active rule](/assets/images/2024/active-rule.png)

**5** - As this rule needs to work within the entire organization we set the target to 'All repositories' and 'All branches'.

![Rule target](/assets/images/2024/rule-target.png)

**6** - For this solution, there are no specific Branch rules, so we deselect the preselected options.

**7** - In the 'Restrictions' section, select 'Restrict branch names' and then select 'Add restriction'. For the requirement, we will select 'Must match a given regex pattern.' This way, we can set up a specific regular expression to check the naming convention.

For our test, we have configured it to:

```bash
^(develop|main)?$|^(bug|feature|hotfix)\/[a-z0-9]+(-[a-z0-9]+)*(-[0-9]+)?$
```

With this regular expression, you can have branching names like:

- main
- develop
- feature\really-cool-new-feature-123
- bug\123
- hotfix\user-data

If you want to try out our regular expression and maybe want to tweak here and there, go check it out on [regular expressions 101](https://regex101.com/r/LA8cPH/1)

![Metadata restriction](/assets/images/2024/metadata-restriction.png)

**8** - Click 'Create' to create the ruleset.

When the ruleset is applied, you can check the insights of your rule by going to: organization settings - Repository - Rule Insights

![Rule Insights](/assets/images/2024/rule-insights.png)