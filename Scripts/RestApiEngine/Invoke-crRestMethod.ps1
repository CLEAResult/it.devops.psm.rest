function Invoke-crRestMethod{
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
      [System.String] Token (optional) - The authentication associated with the Rest API when using Bearer Token authorization.
      [HashTable] $Body (optional) - A hashtable representing the Body of the Rest call, if required.
      [System.String] AuthorizationType - Rest API authorization type.  Do not use, only BearerToken authentication has been implemented.

   .OUTPUTS
      [System.Array] $An array of objects returned by the Rest call, $null if nothing was returned.

   .EXAMPLE
      C:\PS> $Params = @{ RestApi = "ADO"; Service = "Users"; Operation = "List"; organization = "$organization" }
      C:\PS> Invoke-crRestMethod -Params $Params -BearerToken $AdoPAT
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
      [System.String] $BodyJson,

      [Parameter( Mandatory = $false )]
      [System.String] $UploadFile,

      [Parameter( Mandatory = $false )]
      [validateset("application/json", "multipart/form-data" )]
      [System.String] $ContentType = 'application/json',

      [Parameter( Mandatory = $false )]
      [validateset("CustomHeaders","BearerToken","sso-key","Basic","EncryptBasicToken", IgnoreCase = $true)]
      [System.String] $AuthorizationType = $null # Grok, update notes, use to override default behavior in the .json file
   )


   begin {
      Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] - Entering 'begin' block"

      $Result = $null
      [Bool] $RequirementsCheckSucceeded = $true

      Write-Verbose "Username          = $Username"
      Write-Verbose "AuthorizationType = $AuthorizationType"

      try{
         if( -not $AuthorizationType ){
            $AuthorizationType = $Global:crRestApis[$Params["RestApi"]].GeneralInfo.AuthorizationType
         }

         switch( $AuthorizationType ){
            "CustomHeaders" {
               $ValidateHeadersKeys = $Global:crRestApis[$Params["RestApi"]].Requirements.Headers[0]
               $ValidateHeadersKeys | Get-Member -MemberType Properties | ForEach-Object {
                  $CheckForHeader = $ValidateHeadersKeys."$($_.Name)"
                  Write-Verbose $("Checking for header: " + $CheckForHeader)
                  if( -not $Headers[ $CheckForHeader ]){
                     Write-Warning $("Header missing:  $CheckForHeader.  Please include pass a header key/value pair for this call to function correctly." )
                     $RequirementsCheckSucceeded = $false
                  }
               }
            }
            "EncryptBasicToken" {
               Write-Verbose "Using Bearer Token authentication."
               if( $BearerToken ){
                  Write-Verbose "Generating the Base64 token and creating the Rest call's Header."
                  $HeaderTokenBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($BearerToken)"))
                  $Headers += @{authorization = "Basic $HeaderTokenBase64"}
               }
            }
            "BearerToken" {
               Write-Verbose "Using Bearer Token authentication."
               if( $BearerToken ){
                  $Headers += @{authorization = "Bearer $BearerToken"}
               }
            }
            "Basic" {
               Write-Verbose "Using Basic Token authentication."
               if( $Password -and $Username ){
                  Write-Verbose "Generating header for basic authentication using the Username and Password parameters"
                  $HeaderTokenBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Username + ':' + $Password))
                  $Headers += @{ "Authorization" = "Basic $HeaderTokenBase64" }
               }
            }
            "sso-key"{
               Write-Verbose "Using sso-key authentication."
               if( $API_KEY -and $API_SECRET ){
                  $Headers += @{authorization = "sso-key " + $API_KEY + ":" + $API_SECRET}
               }
            }
         }

         Write-Verbose "Loading the request API configuration."
         $RelevantApi = $Global:crRestApis[$Params["RestApi"]].Services | Select-Object -ExpandProperty $Params["Service"] | Where-Object {$_.Operation -eq $Params["Operation"]}
      }
      catch {
         Write-Warning "Error encountered while trying to setup authorization or query the api, returning null: $_"
      }

      Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] - Exiting 'begin' block"
   }

   process {
      Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] - Entering 'process' block"

      if( -not $RequirementsCheckSucceeded ){
         Write-Warning "All requirements were not met, please try again."
      }
      elseif( -not $RelevantApi ){
         Write-Warning "The API configuration was not found, please try again."
      }
      else{
         $Uri = $RelevantApi.Uri
         Write-Verbose "URI (without replacements)= $Uri"

         Write-Verbose "Replacing variables found in the Rest Uri."
         foreach( $key in $Params.GetEnumerator()){
            $Uri = $Uri.Replace( "{$($key.Key)}", $key.Value )
         }
         $Uri = $Uri.Replace( "{version}", $Global:crRestApis[$Params["RestApi"]].GeneralInfo.Version )

         Write-Verbose "URI (with replacements)= $Uri"

         if( $Uri -notlike '*{*}*'){

            if( $Params["AdditionalParams"] ){
               if( $Uri.Contains('?') ){
                  $Uri += "&" + $Params["AdditionalParams"]
               }
               else{
                  $Uri += "?" + $Params["AdditionalParams"]
               }
            }

            # Grok - Adding lines for getting the response headers is a kludge.  ResponseHeadersVariable is supported in PowerShell 7.x not 5.1, hence the commented out code
            # won't work on Azure Automation Hybrid workers which can't yet run against PowerShell 7.  Hoping MS will get this fixed soon as it's a huge pain point!

            if( $Body ){
               Write-Verbose "Making the Rest call with a Body now."
               $RestResult = Invoke-RestMethod -Method $RelevantApi.Method -Uri $uri -Headers $Headers -UseBasicParsing -Body ($Body | ConvertTo-Json -Depth 10) -ContentType $ContentType #-ResponseHeadersVariable ResponseHeadersVariable
               $WebResult = Invoke-WebRequest -Method $RelevantApi.Method -Uri $uri -Headers $Headers -UseBasicParsing -Body ($Body | ConvertTo-Json -Depth 10) -ContentType $ContentType
            }
            elseif( $BodyJson ){
               Write-Verbose "Making the Rest call with a JSON Body now."
               $RestResult = Invoke-RestMethod -Method $RelevantApi.Method -Uri $uri -Headers $Headers -UseBasicParsing -Body $BodyJson -ContentType $ContentType #-ResponseHeadersVariable ResponseHeadersVariable
               $WebResult = Invoke-WebRequest -Method $RelevantApi.Method -Uri $uri -Headers $Headers -UseBasicParsing -Body $BodyJson -ContentType $ContentType
            }
            elseif ( $UploadFile ){
               Write-Verbose "Making the Rest call with upload file now."

               if( Test-Path $UploadFile ){
                  $FileContents = [IO.File]::ReadAllText( $UploadFile );
                  $Fields = @{'uploadFile' = $FileContents };
               }
               else{
                  Write-Warning "$UploadFile not found, skipping!"
               }

               $RestResult = Invoke-RestMethod -Method $RelevantApi.Method -Uri $uri -Headers $Headers -UseBasicParsing -Body $Fields -ContentType $ContentType #-ResponseHeadersVariable ResponseHeadersVariable
               $WebResult = Invoke-WebRequest -Method $RelevantApi.Method -Uri $uri -Headers $Headers -UseBasicParsing -Body $Fields -ContentType $ContentType
            }
            else{
               Write-Verbose "Making the Rest call now."
               $RestResult = Invoke-RestMethod -Method $RelevantApi.Method -Uri $uri -Headers $Headers -UseBasicParsing -ContentType $ContentType # -ResponseHeadersVariable ResponseHeadersVariable
               $WebResult = Invoke-WebRequest -Method $RelevantApi.Method -Uri $uri -Headers $Headers -UseBasicParsing -ContentType $ContentType
            }

            try {
               $Global:ResponseHeadersVariable = $WebResult.Headers
            }
            catch{
               $Global:ResponseHeadersVariable = $null
            }

            Write-Verbose "Ensuring the result is a [System.Array] object."
            if( $RelevantApi.Method -ne "DELETE"){
               if( $RestResult.PSobject.Properties.name -eq "Value" ){`
                  $Result = $RestResult.Value
               }
               elseif( $RestResult.PSobject.Properties.name -eq "Result" ){
                  $Result = $RestResult.Result
               }
               else{
                  $Result = @($RestResult)
               }
            }
            else{
               $Result = $RestResult
            }
         }
         else{
            Write-Warning "Parameters for the ADO Rest API call were missing!"
            Write-Warning "Built URI = $Uri"
            Write-Warning "Run Get-crHelpRestApis for more information about the Rest call you're attempting to make."
         }
      }

      Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] - Exiting 'process' block"
   }

   end {
      Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] - Entering 'end' block"

      Write-Verbose "Returning the final result."
      if( -not $Result ) { Write-Verbose "A null value is being returned in this case."}
      return $Result

      Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] - Exiting 'end' block"
   }
}