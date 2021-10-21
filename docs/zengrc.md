Following are examples of using the ZenGRC API via this module.  This document does not serve as a comprehensive list of all the possible calls but is intended as a set of useful examples.

## Setup
```
$API_KEY = "XYZ"
$API_SECRET = "ABC"
$MY_COMPANY = "Acme"
```

## List all ZenGrcRequests
```
$Params = @{ RestApi = "ZenGrc"; Service = "requests"; Operation = "Requests - List"; organization = $MY_COMPANY }
$List = Invoke-crRestMethod -Params $Params -Username $API_KEY -Password $API_SECRET
```

## Get a specific ZenGRC Request
```
$Params = @{ RestApi = "ZenGrc"; Service = "requests"; Operation = "Requests - Get"; organization = $MY_COMPANY; requestId = "2176" }
$Request = Invoke-crRestMethod -Params $Params -Username $API_KEY -Password $API_SECRET
```

### Create a comment on a ZenGrc Request
```
$Params = @{ RestApi = "ZenGrc"; Service = "requests"; Operation = "Requests - Create Comment"; organization = $MY_COMPANY; requestId = "2176" }
Invoke-crRestMethod -Params $Params -Username $API_KEY -Password $API_SECRET -BodyJson '{"description": "My Best comment ever"}'
```

## Upload a file to a ZenGrc Request
```
$UploadFile = "/Users/ryan.phay/git/github/it.devops.psm.rest/README.md"
$Params = @{ RestApi = "ZenGrc"; Service = "requests"; Operation = "Requests - Upload File"; organization = $MY_COMPANY; requestId = "2176" }
Invoke-crRestMethod -Params $Params -Username $API_KEY -Password $API_SECRET -UploadFile $UploadFile -ContentType "multipart/form-data"
```