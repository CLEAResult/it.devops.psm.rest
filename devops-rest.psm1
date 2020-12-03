[CmdletBinding()]

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]

param()

Set-StrictMode -Version Latest

$Scripts = @(Get-ChildItem -Recurse -Path $PSScriptRoot\Scripts\*.ps1 -ErrorAction SilentlyContinue)

foreach ($import in @($Scripts)) {
   try {
      . $import.fullname
   }
   catch {
      Write-Error -Message "Failed to import function $($import.fullname): $_"
   }
}

#Import the Configuration File
try {
   $Global:crDevOpsRestConfig = Get-Content $PSScriptRoot\config\config.json | ConvertFrom-Json
}
catch {
   Write-Error -Message "There was an error importing the configuration file config\config.json: $_"
}

try{
   $Global:crRestApis.Count
}
catch{
   [Hashtable] $Global:crRestApis = @{}
}

try{
   $RestApiConfigs = Get-ChildItem $PSScriptRoot\config\RestApis\*.json
   foreach( $Config in $RestApiConfigs ){
      $RestApiObj = Get-Content $Config | ConvertFrom-Json
      $ApiName = $RestApiObj.GeneralInfo.Name
      $Global:crRestApis[$ApiName] = $RestApiObj
   }
}
catch{
   Write-Error -Message "There was an error importing one of the Rest API configuration files: $_"
}

