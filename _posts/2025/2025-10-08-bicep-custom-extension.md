---
title: Build a Custom Extension for Bicep
type: post
tags:
- Bicep
- Local
- Extensions
- Http
date: 2025-10-08 01:00:00.000000000 +01:00
permalink: /2025/09/bicep-custom-extension
categories:
- IaC
status: publish
header:
  og_image: /assets/images/2025/custom-extension.png
---

In a previous post about [Bicep Local](https://msftplayground.com/2025/09/bicep-extensions), I explained how this feature enables the creation of custom extensions that can be used directly within Bicep. Also that by using this option you are not limited to the server side implementation that Bicep now has.

If you’re interested in building your own extension, be sure to check out the documentation on [Creating a Local Extension with .Net](https://github.com/Azure/bicep/blob/main/docs/experimental/local-deploy-dotnet-quickstart.md). It’s a great starting point to help you get up and running.

## HTTP Extension

I’ve built an extension that enables performing HTTP requests directly from Bicep. With this capability, a number of powerful scenarios become possible, such as:

* Updating your CMDB automatically when deploying resources to Azure.
* Calling external APIs to retrieve additional data required for deployments.
* Chaining API calls — for example, requesting a token from Microsoft Entra to authenticate a subsequent API call.

The source code of the extension can be found here: [bicep-ext-http](https://github.com/maikvandergaag/bicep-ext-http)

The extension provides a new resource type HttpCall that can perform HTTP requests (GET, POST, PUT, DELETE, PATCH) and capture the response for use in your Bicep templates. This is useful for scenarios like I mentioned above.

### Features

* Multiple HTTP Methods: Supports GET, POST, PUT, DELETE, and PATCH requests
* Custom Headers: Add custom headers to your HTTP requests
* Request Body: Include JSON or other content in request bodies
* Response Capture: Access both the response body and HTTP status code
* Type Safety: Full IntelliSense support and type checking in Bicep

## Creating your own extension

When creating your own extension based on the article I shared earlier, there are a few important considerations and steps to keep in mind. To make this more practical, I’ll walk you through the process using the source code of my own extension as an example.

In my example, I followed specific coding guidelines, which is why my extension differs slightly from the one described in the article. One of the main things that I have changed is the seperation of the code files.

### Program

The core of the extension resides in 'Program.cs'. Using dependency injection, the necessary components are loaded and the extension is assigned its name. As you can see in the snippet below I call my extension 'bicep-ext-http'.

```csharp
using Microsoft.AspNetCore.Builder;
using Bicep.Local.Extension.Host.Extensions;
using Microsoft.Extensions.DependencyInjection;
using Bicep.Ext.Http.Handler;

var builder = WebApplication.CreateBuilder();

builder.AddBicepExtensionHost(args);
builder.Services
    .AddBicepExtension(
        name: "bicep-ext-http",
        version: "1.0.0",
        isSingleton: true,
        typeAssembly: typeof(Program).Assembly)
    .WithResourceHandler<HttpCallHandler>();

var app = builder.Build();

app.MapBicepExtension();

await app.RunAsync();
```

### Deployment Identifier

To deploy a specific resource type, you first need to create an identifier for it. The snippet below shows the identifier I use for my HTTP calls, where I’ve chosen to define it with a simple name.

```csharp
namespace Bicep.Ext.Http.Model {
    public class HttpCallIdentifiers {
        [TypeProperty("The Http Call Name", ObjectTypePropertyFlags.Identifier | ObjectTypePropertyFlags.Required)]
        public required string Name { get; set; }
    }
}
```

### Resource Type

For the resource itself, you need to define a resource type. As you may know, in Bicep every deployment is carried out through a specific resource. The snippet below shows the 'httpcall' resource type that inherits from the Identifer.

This class contains a few properties that defined the resource type and are required to be able to perform a HTTP Call.

```csharp
namespace Bicep.Ext.Http.Model {
    [ResourceType("httpcall")]
    public class HttpCall : HttpCallIdentifiers {

        [TypeProperty("The Http Call Url", ObjectTypePropertyFlags.Required)]
        [JsonPropertyName("url")]
        public required string Url { get; set; }

        [TypeProperty("The HTTP method to use", ObjectTypePropertyFlags.Required)]
        [JsonConverter(typeof(JsonStringEnumConverter))]
        [JsonPropertyName("method")]
        public Method? Method { get; set; }

        [TypeProperty("The body to include in the request")]
        [JsonPropertyName("body")]
        public string? Body { get; set; }

        [TypeProperty("The http call headers")]
        [JsonPropertyName("headers")]
        public Header[]? Headers { get; set; }

        [TypeProperty("The http call result")]
        [JsonPropertyName("result")]
        public string? Result { get; set; }

        [TypeProperty("The http call status code")]
        [JsonPropertyName("statuscode")]
        public int StatusCode { get; set; }
    }
}
```

There are a few important details about this resource type. First, the Method property is defined as an enum (see below). This ensures that only the supported options can be used, preventing invalid inputs and adding the ability to choose a value when defining it in Bicep.

```csharp
namespace Bicep.Ext.Http.Model {
    public enum Method {
        Get,
        Post,
        Put,
        Delete,
        Patch
    }
}
```

Secondly, the 'Headers' property is not defined as a dictionary. Initially, I chose to use a dictionary, but I discovered that the extension model does not support dictionaries. To work around this, I created a custom type called Header and defined Headers as an array property instead. The code below shows this 'Header' type.

```csharp
namespace Bicep.Ext.Http.Model {
    public class Header {
        [TypeProperty("The name.", ObjectTypePropertyFlags.Required)]
        public string? Name { get; set; }

        [TypeProperty("The value.", ObjectTypePropertyFlags.Required)]
        public string? Value { get; set; }
    }
}
```

## This is were the magic happens

The final component of your extension is the 'Handler'. This is where the actions are executed. In my extension, the handler performs the API call and returns its response.

```csharp
namespace Bicep.Ext.Http.Handler {
    public class HttpCallHandler : TypedResourceHandler<HttpCall, HttpCallIdentifiers> {
        protected override async Task<ResourceResponse> Preview(ResourceRequest request, CancellationToken cancellationToken) {
            await Task.CompletedTask;

            return GetResponse(request);
        }

        protected override async Task<ResourceResponse> CreateOrUpdate(ResourceRequest request, CancellationToken cancellationToken) {
            await Task.CompletedTask;

            using (var client = new HttpClient()) {
                var httpRequest = new HttpRequestMessage {
                    Method = request.Properties.Method switch {
                        Method.Get => HttpMethod.Get,
                        Method.Post => HttpMethod.Post,
                        Method.Delete => HttpMethod.Delete,
                        Method.Put => HttpMethod.Put,
                        Method.Patch => HttpMethod.Patch,
                        _ => throw new InvalidOperationException($"Unsupported HTTP method: {request.Properties.Method}"),
                    },
                    RequestUri = new Uri(request.Properties.Url),
                    Content = request.Properties.Body != null ? new StringContent(request.Properties.Body) : null
                };

                if (request.Properties.Headers != null) {
                    foreach (var header in request.Properties.Headers) {
                        if (header.Name != null && header.Value != null) {
                            if (header.Name.Equals("Content-Type", StringComparison.OrdinalIgnoreCase) && httpRequest.Content != null) {
                                httpRequest.Content.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(header.Value);
                            } else {
                                httpRequest.Headers.Add(header.Name, header.Value);
                            }
                        }
                    }
                }

                var response = await client.SendAsync(httpRequest, cancellationToken);
                response.EnsureSuccessStatusCode();

                request.Properties.StatusCode = (int)response.StatusCode;
                request.Properties.Result = await response.Content.ReadAsStringAsync(cancellationToken);
            }

            return GetResponse(request);
        }

        protected override HttpCallIdentifiers GetIdentifiers(HttpCall properties)
            => new() {
                Name = properties.Name,
            };
    }
}
```

In my handler, there are no specific preview capabilities, which is why this method is left for a clear implementation. The 'CreateOrUpdate' method is the part that performs the API call and returns the 'StatusCode' as a output and the result of the call as a string.

## Getting it to work

With all the code in place, the extension is ready to be built. To do this, open a terminal and run the following commands:

```bash
dotnet publish --configuration release -r osx-arm64 .
dotnet publish --configuration release -r linux-x64 .
dotnet publish --configuration release -r win-x64 .

bicep publish-extension --bin-osx-arm64 ./bin/release/osx-arm64/publish/bicep-ext-http --bin-linux-x64 ./bin/release/linux-x64/publish/bicep-ext-http --bin-win-x64 ./bin/release/win-x64/publish/bicep-ext-http.exe --target ./bin/bicep-ext-http --force
```

Next step is to update the 'bicepconfig.json' file to be able to use the extension.

```json
{
  "experimentalFeaturesEnabled": {
    "localDeploy": true,
    "extensibility": true
  },
  "extensions": {
    "http": "./extension-publish/bicep-ext-http"
  },
  "implicitExtensions": []
}
```

Now your defined resource type can be used in bicep.

```yaml
targetScope = 'local'
extension http

var callBody = loadTextContent('sample/body.json')

resource getHttp 'httpcall' = {
  name: 'getcall'
  url: 'https://bicep-local.free.beeceptor.com'
  method: 'Get'
}

resource postHttp 'httpcall' = {
  name: 'postcall'
  url: 'https://bicep-local.free.beeceptor.com'
  method: 'Post'
  headers:[
    {name: 'Content-Type', value: 'application/json' }
  ]
  body: callBody
}

resource deleteHttp 'httpcall' = {
  name: 'deletecall'
  url: 'https://bicep-local.free.beeceptor.com/1'
  method: 'Delete'
}

output getResponse object = json(getHttp.result)
output getStatusCode int = getHttp.statusCode
output postResponse object = json(postHttp.result)
output postStatusCode int = postHttp.statusCode
output deleteStatusCode int = deleteHttp.statusCode
```

## Conclusion

Creating your own extension isn’t difficult and can add powerful capabilities to your infrastructure-as-code workflow.

It’s also worth noting that, at the time of writing, the Bicep team is working on a new deploy command. This will allow Bicep to perform deployments directly, without relying on the Azure CLI or PowerShell, and will also support local deployments. To stay updated on this development, check out this [issue](https://github.com/Azure/bicep/issues/17949).

If you’re looking for extensions, be sure to check out the community-maintained repository. If you’d like to contribute your own extension, don’t hesitate to submit a pull request.

* [Bicep Extension Repository](https://msftplayground.com/bicep-extensions)