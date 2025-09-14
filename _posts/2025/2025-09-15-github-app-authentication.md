---
title: How to Authenticate with the GitHub API Using a GitHub App
type: post
tags:
- GitHub
- App
- Authentication
date: 2025-09-15 01:00:00.000000000 +01:00
permalink: /2025/09/github-app-authentication
categories:
- Azure
status: publish
header:
  og_image: /assets/images/2025/github-app.png
---

When working with GitHub and its APIs, authentication plays a crucial role in ensuring secure and controlled access to repositories, workflows, and organizational data.

While many developers are familiar with classic options like personal access tokens or OAuth apps, GitHub Apps introduce a more modern and scalable approach. Depending on your use case—whether it’s automating workflows, integrating with third-party services, or managing resources at scale—you can choose between several authentication methods. In this post, we’ll explore the available options for authenticating against GitHub’s APIs, with a focus on how GitHub App authentication works from C#.

## Creating an App

To get started with App authentication, you, of course, need a GitHub App. Take the following steps to create your App.

1. Go to your organization settings page within GitHub https://github.com/[organisation]/settings/
2. Click on "GitHub Apps" and then on "New GitHub App".

![GitHub Apps](/assets/images/2025/github-app.png)

{:start="3"}
3. On the "Register new GitHub App" page, fill in all the information that is required for your application.

Next to the general information about the application, the GitHub App can have additional capabilities.

**Identifying and Authorizing users**

A capability to let your GitHub App perform actions on behalf of a user, like creating an issue, posting a comment, or making a deployment.

**Post Installation**

A GitHub App can have specific configurations based on the installation and can also redirect people to a particular page when you update the App within a Repository.

**Webhook**

Webhooks enable your GitHub App to receive real-time notifications when events happen on GitHub.

After providing information about the App and its capabilities, you also need to configure the permissions. In this section, you must clearly specify the permissions the App requires to perform its actions. For this article, we will create an App that registers issues, so we choose "Repository" - "Issues" - "Read and Write".

![GitHub App Permissions](/assets/images/2025/github-app-permissions.png)

Also, make sure that you set the App access. If you want other people to be able to use your application, you have to set it to "Any Account".

When done, click "Create GitHub App"

{:start="4"}
4. When all the information is supplied correctly, you will be directed to the page of your GitHub App where you can provide additional information, like an image for your App. From this page, make sure to copy the App ID and generate a Private Key that we will use during the authentication.

![GitHub App Private Key](/assets/images/2025/github-app-private-key.png)

Download this key, as it will be used for app authentication. As you may have noticed, this page also offers the capability to configure allowed IP addresses for using the App.

With the application in place, we can begin the authentication process. Authenticating with the App is done in several steps:

1. Generate a JWT App Token.
2. Exchange the App Token for an Installation access token.
3. Use the installation access token to call the API's.

## Generate a JWT Token

To generate the JWT token, we need the private key and the appId retrieved from the GitHub App page.

```csharp
private void GenerateJwtToken()
{
    var jwtSecurityTokenHandler = new JwtSecurityTokenHandler { SetDefaultTimesOnTokenCreation = false };
    var rsa = RSA.Create();
    rsa.ImportFromPem(_privateKeyPem.ToCharArray());
    var securityKey = new RsaSecurityKey(rsa);
    var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.RsaSha256);
    var now = DateTime.UtcNow.AddSeconds(-60);
    var token = jwtSecurityTokenHandler.CreateToken(new SecurityTokenDescriptor {
        Issuer = _appId,
        Expires = now.AddMinutes(10),
        IssuedAt = now,
        SigningCredentials = credentials
    });
    _jwt = jwtSecurityTokenHandler.WriteToken(token);
}
```
The above snippet shows a function that takes the Content of the private key as a string and generates a token that expires in 10 minutes.

This token can then be used to get a specific installation token.

## Exchange the App Token for an Installation access token

To exchange the App Token for an installation access token, call the following API: "https://api.github.com/app/installations". 

This API retrieves the installations of the applications, and contains information that is required to be abble to get a installation access token. The information that we need is the URL to request a access token. As you can see in the example below, this is the "access_token_url".

```json
[
  {
    "id": 00000,
    "client_id": "-----",
    "account": {
      "login": "msftplayground",
      "id": 49311642,
      "node_id": "------",
      "avatar_url": "https://avatars.githubusercontent.com/u/49311642?v=4",
      "gravatar_id": "",
      "url": "https://api.github.com/users/msftplayground",
      "html_url": "https://github.com/msftplayground",
      "followers_url": "https://api.github.com/users/msftplayground/followers",
      "following_url": "https://api.github.com/users/msftplayground/following{/other_user}",
      "gists_url": "https://api.github.com/users/msftplayground/gists{/gist_id}",
      "starred_url": "https://api.github.com/users/msftplayground/starred{/owner}{/repo}",
      "subscriptions_url": "https://api.github.com/users/msftplayground/subscriptions",
      "organizations_url": "https://api.github.com/users/msftplayground/orgs",
      "repos_url": "https://api.github.com/users/msftplayground/repos",
      "events_url": "https://api.github.com/users/msftplayground/events{/privacy}",
      "received_events_url": "https://api.github.com/users/msftplayground/received_events",
      "type": "Organization",
      "user_view_type": "public",
      "site_admin": false
    },
    "repository_selection": "selected",
    "access_tokens_url": "https://api.github.com/app/installations/83382606/access_tokens",
    "repositories_url": "https://api.github.com/installation/repositories",
    "html_url": "https://github.com/organizations/msftplayground/settings/installations/83382606",
    "app_id": 1864472,
    "app_slug": "msftplayground-issue-registration",
    "target_id": 49311642,
    "target_type": "Organization",
    "permissions": {
      "issues": "write",
      "metadata": "read"
    },
    "events": [],
    "created_at": "2025-08-29T15:41:16.000Z",
    "updated_at": "2025-08-29T15:41:32.000Z",
    "single_file_name": null,
    "has_multiple_single_files": false,
    "single_file_paths": [],
    "suspended_by": null,
    "suspended_at": null
  }
]
```

The URI shown above is the endpoint you call to obtain the application’s installation access token, which is required for performing actions as the application. In my implementation, I don’t hardcode this URI — instead, I retrieve the exact access_tokens_url by first querying the installation details for a given organization.

```csharp
public async Task<string> GetAccessTokenUrl(string organization, string jwtToken) {

    var client = new HttpClient();
    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", jwtToken);
    client.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue(_appHeader, "1.0"));

    var response = await client.GetAsync(
        $"https://api.github.com/app/installations");

    response.EnsureSuccessStatusCode();
    var json = await response.Content.ReadAsStringAsync();
    var doc = JsonDocument.Parse(json);

    string accessTokensUrl = string.Empty;

    foreach (var installation in doc.RootElement.EnumerateArray()) {

        var account = installation.GetProperty("account");
        var login = account.GetProperty("login").GetString();
        string type = account.GetProperty("type").GetString();

        if(login == organization && type == "Organization"){
            accessTokensUrl = installation.GetProperty("access_tokens_url").GetString();
            break;
        }
    }

    return accessTokensUrl;
}
```

Now that we have the specific URI for the installation access token, we can proceed. The URI can be used in combination with the token to get the installation token.

```csharp
public async Task<string> GetInstallationTokenAsync(string accessTokenUrl, string jwtToken)
{
    var client = new HttpClient();
    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", jwtToken);
    client.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue(_appHeader, "1.0"));
    var response = await client.PostAsync(accessTokenUrl, null);
    response.EnsureSuccessStatusCode();
    var json = await response.Content.ReadAsStringAsync();
    var doc = JsonDocument.Parse(json);
    return doc.RootElement.GetProperty("token").GetString();
}
```

## Use the installation access token to call the API's

The token returned by the "GetInstallationTokenAsync" method can then be used to perform actions on the desired location. The snippet below creates an issue within the specified repository.

```csharp
public async Task<string> CreateIssueAsync(string title, string body)
{
    string retVal = string.Empty;

    string token = GenerateJwtToken();
    var url = await GetAccessTokenUrl(_owner, token);
    var installationToken = await GetInstallationTokenAsync(url, token);
    var client = new HttpClient();
    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", installationToken);
    client.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue(_appHeader, "1.0"));

    var issue = new { title, body };
    var response = await client.PostAsJsonAsync(
        $"https://api.github.com/repos/{_owner}/{_repo}/issues", issue);

    var result = await response.Content.ReadAsStringAsync();
    if (response.IsSuccessStatusCode) {
        var json = await response.Content.ReadAsStringAsync();
        var doc = JsonDocument.Parse(json);
        return doc.RootElement.GetProperty("id").ToString();
    }

    return retVal;
}
```

## Conclusion

GitHub Apps represent a more secure and flexible way of authenticating to GitHub. Besides that, they can also act as a standalone entity. Based on the snippets above, the complete solution looks like this.

```csharp
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text.Json;

namespace App.Core.Services
{
    public class GitHubService
    {
        private readonly string _appId;
        private readonly string _privateKeyPem;
        private readonly string _owner;
        private readonly string _repo;
        private const string _appHeader = "msftplayground-Issue-registration";

        public GitHubService(string appId, string privateKeyPem, string owner, string repo)
        {
            _appId = appId;
            _owner = owner;
            _repo = repo;
            _privateKeyPem = privateKeyPem;
        }

        public string GenerateJwtToken()
        {
            var jwtSecurityTokenHandler = new JwtSecurityTokenHandler { SetDefaultTimesOnTokenCreation = false };

            var rsa = RSA.Create();
            rsa.ImportFromPem(_privateKeyPem.ToCharArray());

            var securityKey = new RsaSecurityKey(rsa);
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.RsaSha256);

            var now = DateTime.UtcNow.AddSeconds(-60);
            var token = jwtSecurityTokenHandler.CreateToken(new SecurityTokenDescriptor {
                Issuer = _appId,
                Expires = now.AddMinutes(10),
                IssuedAt = now,
                SigningCredentials = credentials
            });

            return jwtSecurityTokenHandler.WriteToken(token);
        }

        public async Task<string> GetAccessTokenUrl(string organization, string jwtToken) {

            var client = new HttpClient();
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", jwtToken);
            client.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue(_appHeader, "1.0"));

            var response = await client.GetAsync(
                $"https://api.github.com/app/installations");

            response.EnsureSuccessStatusCode();
            var json = await response.Content.ReadAsStringAsync();
            var doc = JsonDocument.Parse(json);

            string accessTokensUrl = string.Empty;

            foreach (var installation in doc.RootElement.EnumerateArray()) {

                var account = installation.GetProperty("account");
                var login = account.GetProperty("login").GetString();
                string type = account.GetProperty("type").GetString();

                if(login == organization && type == "Organization"){
                    accessTokensUrl = installation.GetProperty("access_tokens_url").GetString();
                    break;
                }
            }

            return accessTokensUrl;
        }

        public async Task<string> GetInstallationTokenAsync(string accessTokenUrl, string jwtToken)
        {
            var client = new HttpClient();
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", jwtToken);
            client.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue(_appHeader, "1.0"));

            var response = await client.PostAsync(accessTokenUrl, null);

            response.EnsureSuccessStatusCode();
            var json = await response.Content.ReadAsStringAsync();
            var doc = JsonDocument.Parse(json);
            return doc.RootElement.GetProperty("token").GetString();
        }

        public async Task<string> CreateIssueAsync(string title, string body)
        {
            string retVal = string.Empty;

            string token = GenerateJwtToken();
            var url = await GetAccessTokenUrl(_owner, token);
            var installationToken = await GetInstallationTokenAsync(url, token);
            var client = new HttpClient();
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", installationToken);
            client.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue(_appHeader, "1.0"));

            var issue = new { title, body };
            var response = await client.PostAsJsonAsync(
                $"https://api.github.com/repos/{_owner}/{_repo}/issues", issue);

            var result = await response.Content.ReadAsStringAsync();
            if (response.IsSuccessStatusCode) {
                var json = await response.Content.ReadAsStringAsync();
                var doc = JsonDocument.Parse(json);
                return doc.RootElement.GetProperty("id").ToString();
            }

            return retVal;
        }
    }
}
```

For additional information, make sure to check out the documentation below.

- [REST API endpoints for GitHub App installations](https://docs.github.com/en/rest/apps/installations?apiVersion=2022-11-28)