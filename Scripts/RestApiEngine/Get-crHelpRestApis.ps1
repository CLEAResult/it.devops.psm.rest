function Get-crHelpRestApis{
<#
   .SYNOPSIS
      Returns information about available Rest API's.

   .DESCRIPTION
      Returns information about available Rest API's that have been published as part of the cr-devops-core module.

   .INPUTS
      [System.String] Api (optional) - Name of the Rest API to display information for.  If empty, all Rest APIs are displayed.
      [System.String] Service (optional) - Name of the Service to display information for.  If empty, all APIs are displayed.
      [Switch] Full - If set, extended information about each Rest API is displayed.
      [Switch] OnlyListApis - If set, only high level information about each available Rest API is displayed.  All other arguments are ignored.

   .OUTPUTS
      Standard output

   .EXAMPLE
      C:\PS> Get-crHelpRestApis

   .EXAMPLE
      C:\PS> Get-crHelpRestApis -OnlyListApis

   .EXAMPLE
      C:\PS> Get-crHelpRestApis -Api "ADO" -Service "Users"
#>

   [CmdletBinding()]

   [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
   [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
   [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
   [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]

   param(
      [Parameter( Mandatory = $false )]
      [System.String] $Api = "*",

      [Parameter( Mandatory = $false )]
      [System.String] $Service = "*",

      [Parameter( Mandatory = $false )]
      [switch] $Full,

      [Parameter( Mandatory = $false )]
      [Switch] $OnlyListApis
   )

   foreach( $RestApi in $Global:crRestApis.Values ){
      $ApiName = $RestApi.GeneralInfo.Name
      $ApiVersion = $RestApi.GeneralInfo.Version
      $ApiDescription = $RestApi.GeneralInfo.Description
      $ApiDocumentation = $RestApi.GeneralInfo.Docs

      if( $OnlyListApis ){
         Write-Host "Available Rest APIs:"
         Write-Host "   - $ApiName"
         Write-Host "     Version: $ApiVersion"
         Write-Host "     Description: $ApiDescription"
         Write-Host "     Documentation: $ApiDocumentation"
      }
      elseif( $ApiName -like $Api ){

         $Title = "$ApiName Rest API Version: $ApiVersion"
         Write-Host $Title
         Write-Host $('=' * $Title.Length)
         Write-Host $RestApi.GeneralInfo.Description
         Write-Host "Documentation: $($RestApi.GeneralInfo.Docs)"
         Write-Host ""

         $RestApi.Services.PSObject.Properties | ForEach-Object {
            $ServiceName = $_.Name

            if( $ServiceName -like "$Service"){
               $SectionTitle = "Service: $ServiceName"
               Write-Host "   $SectionTitle"
               Write-Host $("   " + ('-' * $SectionTitle.Length) )

               foreach( $Method in $_.Value){
                  Write-Host $( "   * " + $Method.Operation + ": " + $Method.Description)
                  if($Full){
                     Write-Host $( "     Rest Method: " + $Action.Method )
                     Write-Host $( "     Rest Uri: " + $Action.Uri )
                     Write-Host $( "     Documentation: " + $Action.Docs )
                  }
               }
               Write-Host ""
            }
         }
      }
   }
}
