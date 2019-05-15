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
    Removes a specified user from all subscriptions to which the running user has access.

.DESCRIPTION
    This script runs under your current Azure Context. To check your Azure Context, run:
      Import-Module Az.Accounts
      Get-AzContext

    As of Az.Accounts Module v1.3.1, there's a little inconsistency in the Get/Set commands. 
    The easiest way I've found to change your Azure Context is:

      Get-AzContext -ListAvailable | ft Name
      Set-AzContext (get-azcontext -Name "NAME-OF-YOUR-DESIRED-CONTEXT-IN-QUOTES")

    Note that you'll need to copy the full value of the Name field, which is rather long.

.PARAMETER UserID

Specify the user ID of the permissions you want to remove.

.PARAMETER Log

Specify the output log file location.

.PARAMETER NoPrompt

Don't ask confirmation before proceeding.

.PARAMETER Guest

Indicates the account you're searching for is a Guest in the target tenant (will convert to user_domain.com format).

.EXAMPLE

.EXAMPLE

#>

param (
    [Parameter(Mandatory=$true)]
    [string]$userID, 
    [string]$logfile = "$env:TEMP\removed-roles.csv",
    [switch] $Guest,
    [switch] $noprompt
)


Install-Module -Name Az.Accounts -AllowClobber -Scope CurrentUser -repository PSGallery -WarningAction SilentlyContinue
Install-Module -Name Az.resources -AllowClobber -Scope CurrentUser -repository PSGallery -WarningAction SilentlyContinue

import-module az.accounts
import-module az.resources

try { get-azsubscription  
} catch {
    Connect-AzAccount
}

$useThisName = ""
remove-item "$logfile" -force -ErrorAction SilentlyContinue

if (-not $noprompt) {
    while (("Y" -notcontains $useThisName.toUpper())) {
        $useThisName = Read-Host "Remove $userID from all subscriptions, is that correct?"
        switch ($useThisName.toUpper()) {
            "Y" { }
            "N" { $userID = Read-Host "Enter the username to remove, or CTRL+C to exit" }
            default { $useThisName = Read-Host "Please enter Y or N" }
        }
    }
}

if ($guest) {
    $userID = $userID.replace("@", "_")
    write-verbose "Guest Account specified. Using $userID to search..." -Verbose
}
$subscriptions = Get-AzSubscription -subscriptionname "Microsoft Azure Internal Consumption"

# Loop through all Subscriptions that you have access to and export the Role information
foreach ($sub in $subscriptions) {

    Write-Verbose -Message "Changing to Subscription $($sub.Name)" -Verbose
    Set-AzContext -SubscriptionObject $sub > $null

    $Name = $sub.Name
    $TenantId = $sub.TenantId

    Get-AzRoleAssignment -IncludeClassicAdministrators | Select RoleDefinitionName, DisplayName, SignInName, ObjectType, Scope, @{name = 'TenantId'; expression = {$TenantId}}, @{name = 'SubscriptionName'; expression = {$Name}} | where signinname -match $userID -OutVariable roles >$null

    foreach ($role in $roles) {

        Write-host -ForegroundColor Green -Message "User $($role.displayname) ($($role.signinname)) has role $($role.roledefinitionname) in $($sub.Name)... removing."

        if ($guest) { $usrobj = get-azaduser -DisplayName $role.displayname | where UserPrincipalName -match "$userID*" } else { $usrobj = get-azaduser -UserPrincipalName $role.signinname }
        
        try {
            $role | Add-member -NotePropertyName "Results" -NotePropertyValue "Success"
            Remove-AzRoleAssignment (get-azroleassignment -ObjectId $usrobj.id) -ErrorAction stop
        }
        catch 
        {
            write-host -ForegroundColor red "Error removing role $($role.roledefinitionname) for $($role.signinname). Skipping..."
            $role | Add-member -NotePropertyName "Results" -NotePropertyValue "Failed"
            continue
        } 
        finally { 
            $role | Export-csv -Path "$logfile" -NoTypeInformation -append -erroraction silentlycontinue
        }
    }

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


