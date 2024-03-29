function Invoke-crRestMethod {
   <#
   .SYNOPSIS
      Calls a Rest API method defined in one of the CLEAResult Rest API configuration files.

   .DESCRIPTION
      Calls a Rest API method defined in one of the CLEAResult Rest API configuration files.  The configuration
      files can be found in the config\ResApis folder of this module.

      In order to use this function the client must know what's required by the target Rest API.  Documentation
      for each API can be found by running Get-crHelpRestApis.ps1.

      First, a set of parameters must be passed to the function in the form of a hashtable.  For example, to use
      the ADO (Azure DevOps) Rest API in order to get a list of users the $Params hashtable should be setup as follows:

      $Params = @{ RestApi = "ADO"; Service = "Users"; Operation = "List"; organization = "$organization" }

      You can also add additional parameters to the URI by simply creating an AdditionalParams string in the $Params variable.
      For example:

      $Params = @{ RestApi = "ADO"; Service = "Users"; Operation = "List"; organization = "$organization"; AdditionalParams = "number=123245&user=john.doe" }

      The name of the RestApi, the name of the Rest Service, and the method or Operation to execute (these are required).
      For this Rest API the name of the target ADO Organization is also required.

      Not sure what variables to pass?  Check out the uri of the RestAPI in the config file.  For example:

      "https://vssps.dev.azure.com/{organization}/_apis/graph/users?api-version={version}"

      While "{version}" can be ignored, any other strings in {}'s must be passed in the $params hashtable.

   .INPUTS
      [Hashtable] Params = Parameters necessary for calling the desired Rest API.
      [System.String] Username (optional) - Not yet implemented.
      [System.String] Password (optional) - Not yet implemented.
      [System.String] BearerToken (optional) - The authentication associated with the Rest API when using Bearer Token authorization.
      [HashTable] $Body (optional) - A hashtable representing the Body of the Rest call, if required.
      [System.String] AuthorizationType - Rest API authorization type.  Do not use, only BearerToken authentication has been implemented.  Valid values are "None", "CustomHeaders", "BearerToken", "sso-key", "Basic", "EncryptBasicToken"
      [Parameter( Mandatory = $true )]
      [Hashtable] $Params,
      [System.String] $API_KEY (optional)
      [System.String] $API_SECRET (optional)
      [HashTable] $Headers = (optional) Hash table of headers to pass in the call.
      [System.String] $BodyJson (optional)
      [System.String] $UploadFile (optional)
      [System.String] $DownloadFile (optional)
      [System.String] $ContentType -  (optional) - Default is 'application/json'; valid values are "application/json", "application/json-patch+json", "multipart/form-data"
      [Switch] $SkipCertificateCheck - (optional)
      [Int] $MaximumRetryCount - (optional) Default is 7.
      [Int] $RetryIntervalSec - (optional) Default is 1.

   .OUTPUTS
      [System.Array] $An array of objects returned by the Rest call, $null if nothing was returned.

   .EXAMPLE
      C:\PS> $Params = @{ RestApi = "ADO"; Service = "Users"; Operation = "List"; organization = "$organization" }
      C:\PS> Invoke-crRestMethod -Params $Params -API_SECRET $AdoPat
#>

   [CmdletBinding()]

   [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
   [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
   [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "")]
   [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUsernameAndPasswordParams", "")]
   [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]

   [OutputType([System.Array])]

   param(
      [Parameter( Mandatory = $true )]
      [Hashtable] $Params,

      [Parameter( Mandatory = $false )]
      [System.String] $Username = $null,

      [Parameter( Mandatory = $false )]
      [System.String] $Password = $null,

      [Parameter( Mandatory = $false )]
      [System.String] $BearerToken,

      [Parameter( Mandatory = $false )]
      [System.String] $API_KEY,

      [Parameter( Mandatory = $false )]
      [System.String] $API_SECRET,

      [Parameter( Mandatory = $false )]
      [HashTable] $Headers = @{},

      [Parameter( Mandatory = $false )]
      [HashTable] $Body,

      [Parameter( Mandatory = $false )]
      [System.String] $BodyRaw,

      [Parameter( Mandatory = $false )]
      [System.String] $BodyJson,

      [Parameter( Mandatory = $false )]
      [System.String] $UploadFile,

      [Parameter( Mandatory = $false )]
      [System.String] $DownloadFile,

      [Parameter( Mandatory = $false )]
      [validateset("application/json", "application/json-patch+json", "multipart/form-data" )]
      [System.String] $ContentType = 'application/json',

      [Parameter( Mandatory = $false )]
      [validateset("None", "CustomHeaders", "BearerToken", "sso-key", "Basic", "EncryptBasicToken", IgnoreCase = $true)]
      [System.String] $AuthorizationType = $null, # Grok, update notes, use to override default behavior in the .json file,

      [Parameter( Mandatory = $false )]
      [Switch] $SkipCertificateCheck,

      [Parameter( Mandatory = $false )]
      [Int] $MaximumRetryCount = 7,

      [Parameter( Mandatory = $false )]
      [Int] $RetryIntervalSec = 1
)


   begin {
      Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] - Entering 'begin' block"
      $Result = $null
      $RestResult = $null

      [Bool] $RequirementsCheckSucceeded = $true
      [Object] $GLobal:WebRequestResult = $null

      Write-Verbose "Username          = $Username"
      Write-Verbose "AuthorizationType = $AuthorizationType"

      try {
         $PowershellVersion7OrLater = $False
         Write-Verbose "Running checks for PowerShell 5.1 vs 7.0+"
         if ( $(Get-Host).Version -lt ([Version] "7.0")) {
            Write-Verbose "The current PowerShell version is less than v7.0, running the appropriate setup steps"
            if ( $SkipCertificateCheck ) {
               Write-Verbose "Certificate check is to be ingored, setting up the TrustAllCertsPolicy class for the call to Invoke-WebRequest via PowerShell < 7.x"
               try {
                  Write-Verbose "Attempting to add custom class TrustAllCertsPolicy"
                  Add-Type @"
                     using System.Net;
                     using System.Security.Cryptography.X509Certificates;
                     public class TrustAllCertsPolicy : ICertificatePolicy {
                        public bool CheckValidationResult(
                              ServicePoint srvPoint, X509Certificate certificate,
                              WebRequest request, int certificateProblem) {
                              return true;
                        }
                     }
"@
                  [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
               }
               catch {
                  Write-Verbose "The policy already exists, skipping"
               }
            }
         }
         else {
            Write-Verbose "The current PowerShell version is equal to or greater than v7.0, running the appropriate setup steps"
            $PowershellVersion7OrLater = $True
         }

         if ( -not $AuthorizationType ) {
            $AuthorizationType = $Global:crRestApis[$Params["RestApi"]].GeneralInfo.AuthorizationType
         }

         switch ( $AuthorizationType ) {
            "CustomHeaders" {
               $ValidateHeadersKeys = $Global:crRestApis[$Params["RestApi"]].Requirements.Headers[0]
               $ValidateHeadersKeys | Get-Member -MemberType Properties | ForEach-Object {
                  $CheckForHeader = $ValidateHeadersKeys."$($_.Name)"
                  Write-Verbose $("Checking for header: " + $CheckForHeader)
                  if ( -not $Headers[ $CheckForHeader ]) {
                     Write-Warning $("Header missing:  $CheckForHeader.  Please include pass a header key/value pair for this call to function correctly." )
                     $RequirementsCheckSucceeded = $false
                  }
               }
            }
            "EncryptBasicToken" {
               Write-Verbose "Usic basic authentication with encryption."
               if ( $API_SECRET ) {
                  Write-Verbose "Generating the Base64 token and creating the Rest call's Header."
                  $HeaderTokenBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($API_KEY):$($API_SECRET)"))
                  $Headers += @{authorization = "Basic $HeaderTokenBase64" }
               }
            }
            "BearerToken" {
               Write-Verbose "Using Bearer Token authentication."
               if ( $BearerToken ) {
                  $Headers += @{authorization = "Bearer $BearerToken" }
               }
            }
            "Basic" {
               Write-Verbose "Using Basic Token authentication."
               if ( $Password -and $Username ) {
                  Write-Verbose "Generating header for basic authentication using the Username and Password parameters"
                  $HeaderTokenBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Username + ':' + $Password))
                  $Headers += @{ "Authorization" = "Basic $HeaderTokenBase64" }
               }
            }
            "sso-key" {
               Write-Verbose "Using sso-key authentication."
               if ( $API_KEY -and $API_SECRET ) {
                  $Headers += @{authorization = "sso-key " + $API_KEY + ":" + $API_SECRET }
               }
            }
         }

         Write-Verbose "Loading the request API configuration."
         $RelevantApi = $Global:crRestApis[$Params["RestApi"]].Services | Select-Object -ExpandProperty $Params["Service"] | Where-Object { $_.Operation -eq $Params["Operation"] }
      }
      catch {
         Write-Warning "Error encountered while trying to setup authorization or query the api, returning null: $_"
      }

      Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] - Exiting 'begin' block"
   }

   process {
      Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] - Entering 'process' block"

      if ( -not $RequirementsCheckSucceeded ) {
         Write-Warning "All requirements were not met, please try again."
      }
      elseif ( -not $RelevantApi ) {
         Write-Warning "The API configuration was not found, please try again."
      }
      else {
         $Uri = $RelevantApi.Uri
         Write-Verbose "URI (without replacements)= $Uri"

         Write-Verbose "Replacing variables found in the Rest Uri."
         foreach ( $key in $Params.GetEnumerator()) {
            $Uri = $Uri.Replace( "{$($key.Key)}", $key.Value )
         }
         $Uri = $Uri.Replace( "{version}", $Global:crRestApis[$Params["RestApi"]].GeneralInfo.Version )

         Write-Verbose "URI (with replacements)= $Uri"

         if ( $Uri -notlike '*{*}*') {

            if ( $Params["AdditionalParams"] ) {
               if ( $Uri.Contains('?') ) {
                  $Uri += "&" + $Params["AdditionalParams"]
               }
               else {
                  $Uri += "?" + $Params["AdditionalParams"]
               }
               Write-Verbose "URI (with additional params)= $Uri"
            }

            try {
               if ( $RelevantApi.BodyJson -and -not $BodyJson ) {
                  Write-Verbose "BodyJson property found for the endpoint, setting!"
                  $BodyJson = $RelevantApi.BodyJson
               }
            }
            catch {
               Write-Verbose "BodyJson property not found for the endpoint, skipping"
            }

            $WebResult = $Null
            if ( $Body ) {
               Write-Verbose "Making the Rest call with a Body now."
               Write-Verbose "Body set to $Body"
               if ( $PowershellVersion7OrLater -and $SkipCertificateCheck ) {
                  $WebResult = Invoke-WebRequest -Method $RelevantApi.Method -Uri $uri -Headers $Headers -UseBasicParsing -Body ($Body | ConvertTo-Json -Depth 10) -ContentType $ContentType -SkipCertificateCheck:$SkipCertificateCheck -MaximumRetryCount $MaximumRetryCount -RetryIntervalSec $RetryIntervalSec
               }
               else {
                  $WebResult = Invoke-WebRequest -Method $RelevantApi.Method -Uri $uri -Headers $Headers -UseBasicParsing -Body ($Body | ConvertTo-Json -Depth 10) -ContentType $ContentType
               }
            }
            elseif ( $BodyRaw ) {
               Write-Verbose "Making the Rest call with a Raw Body now."
               Write-Verbose "Body set to $BodyRaw"
               if ( $PowershellVersion7OrLater -and $SkipCertificateCheck ) {
                  $WebResult = Invoke-WebRequest -Method $RelevantApi.Method -Uri $uri -Headers $Headers -UseBasicParsing -Body $BodyRaw -ContentType $ContentType -SkipCertificateCheck:$SkipCertificateCheck -MaximumRetryCount $MaximumRetryCount -RetryIntervalSec $RetryIntervalSec
               }
               else {
                  $WebResult = Invoke-WebRequest -Method $RelevantApi.Method -Uri $uri -Headers $Headers -UseBasicParsing -Body $BodyRaw -ContentType $ContentType
               }
            }
            elseif ( $BodyJson ) {
               Write-Verbose "Making the Rest call with a JSON Body now."
               Write-Verbose "BodyJson set to $BodyJson"
               if ( $PowershellVersion7OrLater -and $SkipCertificateCheck ) {
                  $WebResult = Invoke-WebRequest -Method $RelevantApi.Method -Uri $uri -Headers $Headers -UseBasicParsing -Body $BodyJson -ContentType $ContentType -SkipCertificateCheck:$SkipCertificateCheck -MaximumRetryCount $MaximumRetryCount -RetryIntervalSec $RetryIntervalSec
               }
               else {
                  $WebResult = Invoke-WebRequest -Method $RelevantApi.Method -Uri $uri -Headers $Headers -UseBasicParsing -Body $BodyJson -ContentType $ContentType
               }
            }
            elseif ( $DownloadFile ) {
               Write-Verbose "Making the Rest call with download file now."

               if ( $PowershellVersion7OrLater -and $SkipCertificateCheck ) {
                  $WebResult = Invoke-WebRequest -Method $RelevantApi.Method -Uri $uri -Headers $Headers -UseBasicParsing -ContentType $ContentType -OutFile $DownloadFile -SkipCertificateCheck:$SkipCertificateCheck -MaximumRetryCount $MaximumRetryCount -RetryIntervalSec $RetryIntervalSec
               }
               else {
                  $WebResult = Invoke-WebRequest -Method $RelevantApi.Method -Uri $uri -Headers $Headers -UseBasicParsing -ContentType $ContentType -OutFile $DownloadFile
               }
            }
            elseif ( $UploadFile ) {
               Write-Verbose "Making the Rest call with upload file now."

               if ( Test-Path $UploadFile ) {
                  $Fields = @{ 'file' = Get-Item $UploadFile }
                  if ( $PowershellVersion7OrLater -and $SkipCertificateCheck ) {
                     $WebResult = Invoke-WebRequest -Method $RelevantApi.Method -Uri $uri -Headers $Headers -UseBasicParsing -form $Fields -ContentType $ContentType -SkipCertificateCheck:$SkipCertificateCheck -MaximumRetryCount $MaximumRetryCount -RetryIntervalSec $RetryIntervalSec
                  }
                  else {
                     # GROK - This solution is admittedly terrible...i.e. this is the most beautiful kludge I've ever been forced to write.  Long story short, I was not able to get Invoke-WebRequest to upload
                     # files in PowerShell 5.x or lower and unfortunately due to issues with Azure Automation Runbooks not being able to run in PowerShell 7 (now there's a preview, but it has it's own limitations).
                     # The solution was to create a script block as a wrapper to start a PowerShell 7 instance with the same parameters.  If anyone can provide the correct solution for doing this natively in
                     # PowerShell 5.1 or lower that would be awesome!  NOTE:  This currently only functions on Windows machines!

                     $ScriptBlock = {
                        function Test([System.String[]] $InputStrings ) {
                           $Split = $InputStrings.Split(';')

                           [hashtable] $Headers = $Split[1] | ConvertFrom-StringData
                           [hashtable] $Fields = @{ 'file' = Get-Item $Split[3] }

                           Invoke-WebRequest -Method $Split[0] -Headers $Headers -Uri $Split[2] -ContentType $Split[4] -form $Fields -UseBasicParsing -SkipCertificateCheck:$SkipCertificateCheck | Export-Clixml "temp.xml" -Force
                        }
                     }

                     [System.String] $HeadersString = ""
                     foreach ( $Key in $Headers.Keys) { $HeadersString += "$Key = $($Headers[$Key])`n"}

                     $MyVars = @( "$($RelevantApi.Method);$HeadersString;$Uri;$UploadFile;$ContentType" )
                     Start-Process "C:\Program Files\PowerShell\7\pwsh.exe" -ArgumentList "-NoProfile -Command & {$ScriptBlock test('$MyVars') }" -Wait -NoNewWindow
                     Start-Sleep 1; $WebResult = (Import-Clixml "temp.xml")
                  }
               }
               else {
                  Write-Warning "$UploadFile not found, skipping!"
               }
            }
            else {
               Write-Verbose "Making the Rest call now."
               if ( $PowershellVersion7OrLater -and $SkipCertificateCheck ) {
                  $WebResult = Invoke-WebRequest -Method $RelevantApi.Method -Uri $uri -Headers $Headers -UseBasicParsing -ContentType $ContentType -SkipCertificateCheck:$SkipCertificateCheck -MaximumRetryCount $MaximumRetryCount -RetryIntervalSec $RetryIntervalSec
               }
               else {
                  $WebResult = Invoke-WebRequest -Method $RelevantApi.Method -Uri $uri -Headers $Headers -UseBasicParsing -ContentType $ContentType
               }
            }

            if ( $WebResult ) {
               Write-Verbose "Invoke-WebRequest Status Code: $($WebResult.StatusCode)"

               Write-Verbose 'Storing the full results in the $Global:WebRequestResult'
               $Global:WebRequestResult = $WebResult

               try {
                  $RestResult = ($WebResult.content | convertfrom-json)
               }
               catch {
                  $ResultResult = $Null
               }
            }

            try {
               $GetProperty = ($Global:crRestApis[$Params["RestApi"]].Services."$($Params["Service"])" | Where-Object { $_.Operation -eq $($Params["Operation"]) }).GetProperty
            }
            catch {
               $GetProperty = $Null
            }

            if ( $RestResult ) {
               if ( $RelevantApi.Method -ne "DELETE") {
                  if ( $GetProperty ) {
                     $Result = $RestResult."$GetProperty"
                  }
                  elseif ( $RestResult.PSobject.Properties.name -eq "Value" ) {
                     $Result = $RestResult.Value
                  }
                  elseif ( $RestResult.PSobject.Properties.name -eq "Result" ) {
                     $Result = $RestResult.Result
                  }
                  else {
                     $Result = @($RestResult)
                  }
               }
               else {
                  $Result = $RestResult
               }
            }
         }
         else {
            Write-Warning "Parameters for the '$($Global:crRestApis[$Params["RestApi"]].GeneralInfo.Name)' Rest API call were missing!"
            Write-Warning "Built URI = $Uri"
            Write-Warning "Run Get-crHelpRestApis for more information about the Rest call you're attempting to make."
         }
      }

      Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] - Exiting 'process' block"
   }

   end {
      Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] - Entering 'end' block"

      Write-Verbose "Returning the final result."
      if ( -not $Result ) { Write-Verbose "A null value is being returned in this case." }
      return $Result

      Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] - Exiting 'end' block"
   }
}