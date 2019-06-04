<#PSScriptInfo
.VERSION .1
.AUTHOR Toby Scales
.COMPANYNAME Microsoft Corporation
.ICONURI
.EXTERNALMODULEDEPENDENCIES 
 - Az.Accounts

.REQUIREDSCRIPTS
 - None

 .EXTERNALSCRIPTDEPENDENCIES
 - None

.RELEASENOTES

    Initial release.

#>
<#

.SYNOPSIS
    Finds RBAC info from all subscriptions to which the running user has access.

.DESCRIPTION
    This script runs under your current Azure Context. To check your Azure Context, run:
      Import-Module Az.Accounts
      Get-AzContext

    As of Az.Accounts Module v1.3.1, there's a little inconsistency in the Get/Set commands. 
    The easiest way I've found to change your Azure Context is:

      Get-AzContext -ListAvailable | ft Name
      Set-AzContext (get-azcontext -Name "NAME-OF-YOUR-DESIRED-CONTEXT-IN-QUOTES")

    Note that you'll need to copy the full value of the Name field, which is rather long.

.PARAMETER LogFile

Specify the output log file location.

.EXAMPLE
Get-AzRBAC.ps1 -LogFile output.csv

#>

param (
    [string]$logfile = "$env:TEMP\list-roles.csv"
)


Install-Module -Name Az.Accounts -AllowClobber -Scope CurrentUser -repository PSGallery -WarningAction SilentlyContinue
Install-Module -Name Az.resources -AllowClobber -Scope CurrentUser -repository PSGallery -WarningAction SilentlyContinue

import-module az.accounts
import-module az.resources

if (-not (get-azsubscription)) {  
    Connect-AzAccount
}

remove-item $logFile -force -ErrorAction SilentlyContinue

$contexts = Get-AzContext -listavailable 
# Loop through all Subscriptions that you have access to and export the Role information
foreach ($context in $contexts) {

    Write-Verbose -Message "Changing to Subscription $($context.Subscription.Name)"
    Set-AzContext $context > $null

    $Name = $context.Subscription.Name
    $TenantId = $context.Subscription.TenantId

    Get-AzRoleAssignment -IncludeClassicAdministrators | Select RoleDefinitionName, DisplayName, SignInName, ObjectType, Scope,
    @{name = 'TenantId'; expression = {$TenantId}}, @{name = 'SubscriptionName'; expression = {$Name}} -OutVariable roles >$null

    $roles | Export-csv -Path "$logfile" -NoTypeInformation -append -erroraction silentlycontinue

}

if (get-item "$logFile" -ErrorAction SilentlyContinue) {

    Try {
        invoke-item "$logFile" -ErrorAction Stop
    }
    catch {
        write-host -ForegroundColor yellow "Unable to open output file. Check results at $logfile."
    }
}
else { write-host -foregroundColor red "No results found. Check permissions?"}

