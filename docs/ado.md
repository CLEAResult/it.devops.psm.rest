Following are examples of using the Azure DevOps API via this module.  This document does not serve as a comprehensive list of all the possible calls but is intended as a set of useful examples.

## Setup
```
$AdoOrganization = "MY_AZURE_DEVOPS_ORGANIZATION_NAME"
$AdoProject      = "SOME_AZURE_DEVOPS_PROJECT_NAME"
$AdoProjectId    = "SOME_AZURE_DEVOPS_PROJECT_ID
$AdoPAT          = "MY_AZURE_DEVOPS_PERSONAL_ACCESS_TOKEN"
$UserId          = "SOME_USER_ID"
```

## Build Service
```
$Params = @{ RestApi = "ADO"; Service = "Build"; Operation = "Definitions - List"; project = $AdoProject; organization = $AdoOrganization }
$AdoBuildDefs = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat

$BuildDefId = 666
$Params = @{ RestApi = "ADO"; Service = "Build"; Operation = "Definitions - Get"; project = $AdoProject; organization = $AdoOrganization; definitionId = $BuildDefId }
$AdoBuildDef = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat

$Params = @{ RestApi = "ADO"; Service = "Build"; Operation = "Builds - List"; project = $AdoProject; organization = $AdoOrganization }
$AdoBuilds = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat
```

## Git Service
```
$Params = @{ RestApi = "ADO"; Service = "Git"; Operation = "Repositories - List"; organization = $AdoOrganization; project = $AdoProject }
$Repos = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat

$RepoID = $Repos[0].Id
$Params = @{ RestApi = "ADO"; Service = "Git"; Operation = "Policy Configurations - Get"; organization = $AdoOrganization; project = $AdoProject; repositoryId = $RepoId }
$PolicyConfigurations = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat
```

## Member Entitlement Management Service
```
$Params = @{ RestApi = "ADO"; Service = "Member Entitlement Management"; Operation = "Group Entitlements - List"; organization = $AdoOrganization }
$UserEntitlements = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat

$GroupId = ($UserEntitlements | Where-Object { $_.Group.PrincipalName -eq "[$AdoOrganization]\Some Group Rule"}).Id

$Params = @{ RestApi = "ADO"; Service = "Member Entitlement Management"; Operation = "Members - Get"; organization = $AdoOrganization; groupId = $groupId}
$Members = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat
$Members.members.user

$Params = @{ RestApi = "ADO"; Service = "Member Entitlement Management"; Operation = "Get User Entitlement"; userId = $UserId; organization = $AdoOrganization }
$UserEntitlements = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat
```

## Permissions Report Service
```
$Params = @{ RestApi = "ADO"; Service = "Permissions Report"; Operation = "Permissions Report - List"; organization = $AdoOrganization }
$PermissionsReports = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat

$Params = @{ RestApi = "ADO"; Service = "Permissions Report"; Operation = "Permissions Report - Get"; organization = $AdoOrganization; id = "REPORT_ID"}
$PermissionsReport = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat

# The following demonstrates generating a report, manual download, and converting to an excel file

$Params = @{ RestApi = "ADO"; Service = "Projects"; Operation = "List"; organization = $AdoOrganization }
$Projects = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat

$CurrentProject = $Projects[0]

$PermissionsReportResources = @()
$PermissionsReportResources += @{ resourceId = @( $CurrentProject.Id ); resourceName = "REPOSITORY_NAME"; resourceType = "projectGit"}
$Body = @{ descriptors = @(); reportName = "MyReport"; resources = $PermissionsReportResources }
$Params = @{ RestApi = "ADO"; Service = "Permissions Report"; Operation = "Permissions Report - Create"; organization = $AdoOrganization}
$ReportLink = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat -Body $Body

# Note, ReportLink doesn't provide anything useful except to download the json file manually in a browser...

$ReportObj = Get-Content "./DownloadedReport.json" | ConvertFrom-Json
foreach( $Item in $ReportObj ){
    $Item.permissions | Export-Excel -WorksheetName $Item.DisplayName -Table $Item.DisplayName ./Output.xlsx
}
```

## Personal Access Tokens Service
```
$Params = @{ RestApi = "ADO"; Service = "Personal Access Tokens"; Operation = "List"; organization = $AdoOrganization; subjectDescriptor = $UserId }
$UserPATs = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat

```

## Projects Service
```
$Params = @{ RestApi = "ADO"; Service = "Projects"; Operation = "List"; organization = $AdoOrganization }
$AdoProjects = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat
```

## Release Service
```
$Params = @{ RestApi = "ADO"; Service = "Release"; Operation = "Definitions - List"; project = $AdoProject; organization = $AdoOrganization }
$AdoReleaseDefs = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat
```

## Task Agent Service
```
$Params = @{ RestApi = "ADO"; Service = "Task Agent"; Operation = "Environments - List"; project = $AdoProject; organization = $AdoOrganization }
$Environments = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat

$Params = @{ RestApi = "ADO"; Service = "Task Agent"; Operation = "Environments - Get"; project = $AdoProject; organization = $AdoOrganization; environmentId = "41"}
$Environment = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat

$Params = @{ RestApi = "ADO"; Service = "Task Agent"; Operation = "Pools - Get Agent Pools"; organization = $AdoOrganization }
$AdoAgentPools = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat
$AdoAgents = @()
foreach( $Pool in $AdoAgentPools ){
   $Params = @{ RestApi = "ADO"; Service = "Task Agent"; Operation = "Agents - List"; poolId = $Pool.ID; organization = $AdoOrganization }
   $AdoAgents += Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat
}
```

## Teams Service
```
$Params = @{ RestApi = "ADO"; Service = "Teams"; Operation = "Get All Teams"; organization = $AdoOrganization }
$AdoTeams = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat

$Params = @{ RestApi = "ADO"; Service = "Teams"; Operation = "Create"; organization = $AdoOrganization; projectId = $AdoProjectId }
foreach($Team in $AdoTeams){
   $TeamName = $Team.Name
   $Body = @{ name = $("$TeamName"); description = "Ported from the $AdoOrganization ADO Organization." }
   Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat -Body $Body
}
```

## Users Service
```
$Params = @{ RestApi = "ADO"; Service = "Users"; Operation = "List"; organization = $AdoOrganization }
$AdoUsers = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat

$Params = @{ RestApi = "ADO"; Service = "Users"; Operation = "Get"; organization = $AdoOrganization; userDescriptor = $UserId }
$GetUser = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat

$Params = @{ RestApi = "ADO"; Service = "Users"; Operation = "Delete"; organization = $AdoOrganization; userDescriptor = $UserId }
Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat

$Body = @{ principalName = "first.last@mycompany.com" }
$Params = @{ RestApi = "ADO"; Service = "Users"; Operation = "Create"; organization = $AdoOrganization }
Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat -Body $Body
```

## Work Item Tracking Service
```
$Params = @{ RestApi = "ADO"; Service = "Work Item Tracking"; project = $AdoProject; Operation = "Queries - List"; organization = $AdoOrganization }
$SharedQueriesParent = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat | where-object { $_.Name -eq "Shared Queries" }

$Params = @{ RestApi = "ADO"; Service = "Work Item Tracking"; project = $AdoProject; Operation = "Queries - List"; organization = $AdoOrganization }
$AdoQueries = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat

$Params = @{ RestApi = "ADO"; Service = "Work Item Tracking Process"; Operation = "Processes - List"; organization = $AdoOrganization }
Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat

$typeId = "TYPE_ID_GOES_HERE"
$Params = @{ RestApi = "ADO"; Service = "Work Item Tracking Process"; Operation = "Processes - Get"; organization = $AdoOrganization; processTypeId = $TypeId}
Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat

$Params = @{ RestApi = "ADO"; Service = "Work Item Tracking Process"; Operation = "Work Item Types - List"; organization = $AdoOrganization; processId = $TypeId}
Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat

$witRefName = "Agile.Bug"
$Params = @{ RestApi = "ADO"; Service = "Work Item Tracking Process"; Operation = "States - List"; organization = $AdoOrganization; processId = $TypeId; witRefName = $witRefName}
Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat

$Params = @{ RestApi = "ADO"; Service = "Work Item Tracking Process"; Operation = "Fields - List"; organization = $AdoOrganization; processId = $TypeId; witRefName = $witRefName}
Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat

$AdoQueryChildren = $AdoQueries[0].Children
$QueryID = "QUERY_ID_GOES_HERE"
$Params = @{ RestApi = "ADO"; Service = "Work Item Tracking"; project = $AdoProject; query = $QueryID; Operation = "Queries - Get"; organization = $AdoOrganization }
$AdoQuery = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat

$Team = "ADO_TEAM_NAME_GOES_HERE"
$AdoQuery = $AdoQueryChildren[1].children[0]
$QueryID = "QUERY_ID_GOES_HERE"
$Params = @{ RestApi = "ADO"; Service = "Work Item Tracking"; project = $AdoProject; team = $Team; id = $QueryID; Operation = "Wiql - Query By Id"; organization = $AdoOrganization }
$RanQuery = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat
$WorkItems = $RanQuery.WorkItems

$Bob = @()
foreach($wi in $WorkItems){
   $Params = @{ RestApi = "ADO"; Service = "Work Item Tracking"; project = $AdoProject; id = $wi.id; Operation = "Work Items - Get Work Item"; organization = $AdoOrganization }
   $WorkItemInfo = Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat
   $bob += $WorkItemInfo.Fields
}
$bob | export-excel -path "./bob.xlsx"
```