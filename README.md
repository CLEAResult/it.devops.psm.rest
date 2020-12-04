# The Open Source it.devops.psm.rest PowerShell Module

## Introduction

The it.devops.psm.rest PowerShell module was first developed in-house by CLEAResult.inc as a larger, company specific, PowerShell module for more easily interacting with REST APIs.  Realizing it's usefulness I decided to split out REST functionality that can be shared more broadly.

## Contributing

In general, only updates and additions to the REST API definitions files should need to be made to make this module more comprehensive however I've never claimed to be a REST guru so any non-breaking improvements to the engine are appreciated.  Having said that anyone is free to contribute to this module, just make the appropriate Pull Request and as always, don't store API information specific to you or your organization in the REST API definitions.

## What Can I Do?

To see what the module's currently capable of you can dig into the API Definition files (more information below) or simply call:
```
Get-crHelpRestApis.ps1
```
This will list all available REST API's and corresponding endpoints.  This is pretty comprehensive so pin it down by passing parameters.  Here's the help:
```
NAME
    Get-crHelpRestApis

SYNOPSIS
    Returns information about available Rest API's.


SYNTAX
    Get-crHelpRestApis [[-Api] <String>] [[-Service] <String>] [-Full] [-OnlyListApis] [<CommonParameters>]


DESCRIPTION
    Returns information about available Rest API's that have been published as part of the cr-devops-core module.


PARAMETERS
    -Api <String>
        Required?                    false
        Position?                    1
        Default value                *
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Service <String>
        Required?                    false
        Position?                    2
        Default value                *
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Full [<SwitchParameter>]
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -OnlyListApis [<SwitchParameter>]
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
```

## API Definition JSON Files

The it.devops.psm.rest module allows PowerShell users to quickly and easily add REST API's and the desired endpoints by simply adding or modying JSON config files found in the .\config\RestApis folder.

The format of the JSON files is as follows:
```
{
  "GeneralInfo": {
    "Name": "REST_API_NAME",
    "Description": "Description of the API",
    "AuthorizationType": "AUTHORIZATION_TYPE",
    "version": "OPTIONAL_API_VERSION",
    "Docs": "OPTIONAL_LINK_TO_MAIN_DOCUMENTATION_PAGE"
  },
  "Requirements": {
    "Headers": [
      {
        "Item1": "x-auth-email",
        "Item2": "x-auth-key"
      }
    ]
  },
  "Services": {
    "SERVICE_NAME": [
      {
        "Operation": "OPERATION_NAME",
        "Method": "GET SET ETC...",
        "Uri": "API_ENDPOINT_URI",
        "Description": "DESCRIPTION_FOR_THE_ENDPOINT",
        "Docs": "URL_TO_THE_ENDPOINT_DOCUMENTATION"
      }
    ]
  }
}
```

The _Requirements_ section is only required when the _AuthorizationType_ is set to "CustomHeaders".

*Note:*  REST_API_NAME should match the filename minus the file's extension.

## Authorization Types

The module current supports the following REST API authorization types:

* CustomHeaders
* BearerToken
* Basic
* sso-key

## Variables

In both the REST API definition files as well as calls to the module's engine, Variables are represented as:
```
{variable}
```

## Usage

The module is fairly straight forward to use.  Import it (obviously) then set up a hashtable to pass your variables in then call Invoke-crRestMethod.  For example, to retrieve Release Definitions from the Azure DevOps (ADO) API you'd make the following call:

```
[hashtable] $Params = @{ RestApi = "ADO"; Service = "Release"; Operation = "Definitions - List"; project = "MY_ADO_PROJECT"; organization = "MY_ADO_ORGANIZATION" }
$AdoReleaseDefs = Invoke-crRestMethod -Params $Params -BearerToken "YOUR_ADO_PERSONAL_ACCESS_TOKEN_GOES_HERE"
```

RestAPi, Service, and Operation are required by all calls to INvoke-crRestMethod.  Any other variable passed will be used to interpret the corresponding REST API definition.

For example, in this case I'm passing MY_ADO_PROJECT and MY_ADO_ORGANIZATION as parameters.  The JSON data defines the API as follows:
```
{
    "Operation": "Definitions - List",
    "Method": "GET",
    "Uri": "https://vsrm.dev.azure.com/{organization}/{project}/_apis/release/definitions?api-version={version}",
    "Description": "Get a list of release definitions.",
    "Docs": "https://docs.microsoft.com/en-us/rest/api/azure/devops/release/definitions/list?view=azure-devops-rest-5.1"
},
```
When the call is made the module will replace the variables {project} and {organization} with MY_ADO_PROJECT and MY_ADO_ORGANIZATION, respectively.  The {version} variable (optional) is defined in the GeneralInfo section of the JSON file.

The resulting URL called will end up being:
```
https://vsrm.dev.azure.com/MY_ADO_ORGANIZATION/MY_ADO_PROJECT/_apis/release/definitions?api-version=5.1
```

Output returned rom called to Invoke-crRestMethod standard Object Arrays that can be manipulated to your heart's content.

### Enjoy!