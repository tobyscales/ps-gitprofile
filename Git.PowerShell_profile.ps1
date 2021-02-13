###########################################################
#
# tescales Custom Git.Profile
#
# Sources:
#  https://hodgkins.io/ultimate-powershell-prompt-and-git-setup
#  https://joonro.github.io/blog/posts/powershell-customizations.html
#  https://github.com/scottmuc/poshfiles/blob/master/Microsoft.PowerShell_profile.ps1
# 
###########################################################

#$ErrorActionPreference = 'SilentlyContinue'

#region convenience functions
function which($name) { Get-Command $name | Select-Object Definition }
function rm-rf($item) { Remove-Item $item -Recurse -Force }
function touch($file) { "" | Out-File $file -Encoding ASCII }

#endregion functions

$here = (split-path $profile)
$isAdmin = $false
$isTransient = $true

#write-verbose "Loading $env:LocalGitProfile from $($MyInvocation.InvocationName)"

switch ($true) {
    $isWindows {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    }
    $isLinux { 
        #TODO: $isAdmin = something;
    }
    $isMacOS { 
        #TODO: $isAdmin = something;
    }
} 

$gitOwner = split-path ($env:gitProfile)
$gitRepo = split-path ($env:gitProfile) -leaf
. global:Import-RequiredFunctions $env:gitProfile

#env:LocalGitProfile means we're persisting a profile
if ($env:LocalGitProfile -and $isConnected) {
    #env:storageKey means we're mounting a cloudshell
    if ($env:storageKey) { 
        $cloudShell = (Mount-CloudShellDrive -storageAcct $env:storagePath.split('.')[0] -storageKey $env:storageKey -shareName $env:storagePath.split('\')[-1] ); write-host "Mapped Cloud drive to $($cloudShell.Root)"; set-location $cloudShell.Root 
    }
    write-host -ForegroundColor yellow "Cloning functions from $gitRepo..."

    . import-gitfunction get-gitfiles
    . import-gitfunction "New-Runspace" -GitProfile "pldmgg/misc-powershell" -subPath "MyFunctions/PowerShellCore_Compatible"
    Get-GitFiles -Owner $gitOwner -Repository $gitRepo -Path "functions" -DestinationPath "$here\functions"
    Get-GitFiles -Owner $gitOwner -Repository $gitRepo -Path "scripts" -DestinationPath "$here\scripts"
    #New-Runspace -runspacename "PS Clone Functions" -scriptblock { Get-GitFiles -Owner $gitOwner -Repository $gitRepo -Path functions -DestinationPath "$here\functions" }
    #New-Runspace -runspacename "PS Clone Scripts" -scriptblock { Get-GitFiles -Owner $gitOwner -Repository $gitRepo -Path Scripts -DestinationPath "$here\scripts" }       
}


#switch ($global:isConnected) {
#    $true {
#$runspaceURL = "https://raw.githubusercontent.com/pldmgg/misc-powershell/master/MyFunctions/PowerShellCore_Compatible/New-Runspace.ps1"
#Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($runspaceURL)) 

#$getGFURL = "https://raw.githubusercontent.com/tobyscales/ps-gitprofile/master/functions/Get-GitFiles.ps1"
#Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($getGFURL))

        
#else {
# Non-persistent function loader
##$wr = Invoke-WebRequest -Uri "https://api.github.com/repos/$gitOwner/$gitRepo/contents/functions/!required"
##$objects = $wr.Content | ConvertFrom-Json
##$files = $objects | where-object { $_.type -eq "file" } | Select-object -exp download_url

##foreach ($file in $files) {
##    try {
##       invoke-expression ((New-Object System.Net.WebClient).DownloadString($file)) -ErrorAction Stop
##  }
##    catch {
##        throw "Unable to download '$($file.path)'"
##    }
##}
#}
#}
#$false { #not connected
 #   $here = (split-path -$env:LocalGitProfile).tostring()
#}
#}

write-Verbose "Now running Git.PowerShell from: $here"

if (-not $isAdmin) {
    if ($isWindows) {
        #used for when cloud-shell is mapped as a drive; wish there was a better way around this!
        # (can't use unblock-file because SMB shares don't support FileStream Zone.Identifiers)
        # would be ideal --> get-item $here\functions\*.ps1 | Unblock-File
        Set-ExecutionPolicy Bypass -Scope Process -Force
    }

    $TransientScriptDir = "$here\scripts"
    #$UserBinDir = "$($home)\bin"
    
    # PATH update
    #
    # creates paths to every subdirectory of userprofile\bin
    # adds a transient script dir that I use for experiments
    $paths = @("$($env:Path)", $TransientScriptDir)
    #Get-ChildItem $UserBinDir | ForEach-Object { $paths += $_.FullName }
    $env:Path = [String]::Join("; ", $paths) 
    
}

#OLD/FUTURE USE CODE
# if you want to add functions you can add scripts to your
# powershell profile functions directory or you can inline them
# in this file. Ignoring the dot source of any tests
#write-host "Re-loading functions."
#$importC= "https://raw.githubusercontent.com/beatcracker/Powershell-Misc/master/Import-Component.ps1"
#Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($importC))
#. Import-Component "(split-path $profile)\functions" -type PS -recurse

#Invoke-RequiredFunctions -owner $gitOwner -repository $gitRepo -Path 'functions/!required'
# load all script modules available to us
#Get-Module -ListAvailable | where-object { $_.ModuleType -eq "Script" } | Import-Module
#Resolve-Path $here\functions\*.ps1 | Where-Object { -not ($_.ProviderPath.Contains(".Tests.")) } | ForEach-Object { . $_.Path } #$filen=$_.Path; unblock-file -Path $filen;
#Resolve-Path $here\functions\!required\*.ps1 | 
#Where-Object { -not ($_.ProviderPath.Contains(".Tests.")) } |
#ForEach-Object { . $_.ProviderPath; write-host ". $($_.ProviderPath)" }
 