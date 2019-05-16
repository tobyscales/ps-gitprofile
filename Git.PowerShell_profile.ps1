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

# TO ADD: auto-import ARM snippets: https://danielpaulus.com/arm-templates-with-visual-studio-code/
# TO ADD: auto-debug ARM tempaltes: https://azure.microsoft.com/en-us/blog/debugging-arm-template-deployments/
# TO ADD: CSS-styling for GH Markdown: https://gist.github.com/JamesMessinger/5d31c053d0b1d52389eb2723f7550907
# TODO: add "isAdmin" check for Linux root

#$ErrorActionPreference = 'SilentlyContinue'

#region functions
function Mount-CloudShell {
    if ($env:isConnected) {
        switch ($true) {
            $isWindows {
                if (Get-PSDrive -name S) {
                    Write-Verbose "Found S:\ drive."
                    return $true
                }
                else {
                    $acctUser = $env:storagePath.split('.')[0]
                    $acctKey = ConvertTo-SecureString -String $env:storageKey -AsPlainText -Force
                    $credential = New-Object System.Management.Automation.PSCredential -ArgumentList "Azure\$acctUser", $acctKey

                    try {
                        New-PSDrive -Name S -PSProvider FileSystem -Root "\\$env:storagePath" -Credential $credential -Persist -Scope Global -ErrorAction Stop
                        Write-Verbose "Mapped drive \\$env:storagePath using $($credential.UserName)"
                        return $true
                    }
                    catch {
                        Write-Host -ForegroundColor Darkred "Error mapping cloudshell drive at $env:storagePath."
                        return $false
                    }
                }                
            }
            $isLinux {
                if (Get-PSDrive -name "cloudshell" -ErrorAction SilentlyContinue) {
                    return $true
                }
                else {
                    $acctUser = $env:storagePath.split('.')[0]
                    $acctKey = ConvertTo-SecureString -String $env:storageKey -AsPlainText -Force
                    $credential = New-Object System.Management.Automation.PSCredential -ArgumentList "Azure\$acctUser", $acctKey

                    try {
                        # apparently New-PSDrive is still pretty broken, per https://github.com/PowerShell/PowerShell/issues/6629
                        #New-PSDrive -Name S -PSProvider FileSystem -Root "//$env:storagePath/$env:storageShare" -Credential $credential -Persist -Scope Global -ErrorAction Stop
                        #Write-Verbose "Mapped drive //$env:storagePath\$env:storageShare using $($credential.UserName)"

                        if (-not (test-path "$home/cloudshell")) { new-item -path $home/cloudshell -ItemType Directory | Out-Null }
                        try {
                            Invoke-Expression "sudo mount -t cifs -o username=$credential.UserName,password=$env:storageKey //$env:storagePath $home/cloudshell" -ErrorAction Stop
                        }
                        catch {
                            Write-Host -ForegroundColor DarkRed "Error mapping cloudshell drive at $env:storagePath."
                            return $false
                        }
                        Write-Verbose "Mapped drive \\$env:storagePath using $($credential.UserName)"
                        return $true
                    }
                    catch {
                        Write-Host -ForegroundColor Darkred "Error mapping cloudshell drive at $env:storagePath."
                        return $false
                    }
                }                
            }
            $IsMacOS {
                Write-Host "Cloud Shell Mapping not yet enabled for MacOS, sorry."
                return $false
            }
        }    
    }
    else { return $env:isConnected }
}

#endregion

if ($env:LocalGitProfile) { $here = split-path($env:LocalGitProfile) } else { $here = split-path($profile) }
$isAdmin = $false

write-verbose "Loading $env:LocalGitProfile from $here and $($MyInvocation.InvocationName)"

switch ($true) {
    $isWindows {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        if ( ($env:storageKey) -and (Mount-CloudShell) ) { $here = "S:" }
    }
    $isLinux { 
        #TODO: $isAdmin = something;
        if ( ($env:storageKey) -and (Mount-CloudShell) ) { $here = "$home/cloudshell" }
    }
    $isMacOS { }
} 

write-host -ForegroundColor Yellow "Running Git.PowerShell from: $here"

if ($env:isConnected) {
    $runspaceURL = "https://raw.githubusercontent.com/pldmgg/misc-powershell/master/MyFunctions/PowerShellCore_Compatible/New-Runspace.ps1"
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($runspaceURL)) 
    
    $getGFURL = "https://raw.githubusercontent.com/tescales/powershell-gitprofile/master/functions/Get-GitFiles.ps1"
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($getGFURL))

    $invokeRFURL = "https://raw.githubusercontent.com/$gitProfile/master/functions/Invoke-RequiredFunctions.ps1"
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($invokeRFURL))

    $gitOwner = split-path ($env:gitProfile)
    $gitRepo = split-path ($env:gitProfile) -leaf
    write-host -ForegroundColor yellow "Loading !required functions from $gitRepo..."
    set-location -Path "$here"

    #$gitRepo = "https://github.com/" + $env:gitProfile.substring(34, $env:gitProfile.indexOf("/master") - 34) + ".git" 
    #new-runspace -runspacename "Git Clone" -scriptblock { git clone $gitRepo }
    Get-GitFiles -Owner $gitOwner -Repository $gitRepo -Path functions\!required -DestinationPath "$here\functions\!required"
    #New-Runspace -runspacename "PS Clone" -scriptblock { Get-GitFiles -Owner $gitOwner -Repository $gitRepo -DestinationPath $here }
}
if (-not $isAdmin) {

    #used for when cloud-shell is mapped as a drive; wish there was a better way around this!
    # (can't use unblock-file because SMB shares don't support FileStream Zone.Identifiers)
    # would be ideal --> get-item $here\functions\*.ps1 | Unblock-File
    Set-ExecutionPolicy Bypass -Scope Process -Force

    # function loader
    #
    # if you want to add functions you can added scripts to your
    # powershell profile functions directory or you can inline them
    # in this file. Ignoring the dot source of any tests
    #write-host "Re-loading functions."
    #$importC= "https://raw.githubusercontent.com/beatcracker/Powershell-Misc/master/Import-Component.ps1"
    #Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($importC))
    #. Import-Component "C:\Users\toscal\OneDrive - Microsoft\Repos\Github\ps-gitprofile\functions" -type PS -recurse
    Invoke-RequiredFunctions -owner (split-path $gitProfile) -repository (split-path $gitProfile -leaf) -Path 'functions/!required'
    # load all script modules available to us
    #Get-Module -ListAvailable | where-object { $_.ModuleType -eq "Script" } | Import-Module
    #Resolve-Path $here\functions\*.ps1 | Where-Object { -not ($_.ProviderPath.Contains(".Tests.")) } | ForEach-Object { . $_.Path } #$filen=$_.Path; unblock-file -Path $filen;
    #Resolve-Path $here\functions\!required\*.ps1 | 
    #Where-Object { -not ($_.ProviderPath.Contains(".Tests.")) } |
    #ForEach-Object { . $_.ProviderPath; write-host ". $($_.ProviderPath)" }
    foreach ($file in Get-ChildItem $here\functions\!required\*.ps1) {
        . (
            [scriptblock]::Create(
                [io.file]::ReadAllText($file)
            )
        )
    }
} 


# inline functions, aliases and variables
function which($name) { Get-Command $name | Select-Object Definition }
function rm-rf($item) { Remove-Item $item -Recurse -Force }
function touch($file) { "" | Out-File $file -Encoding ASCII }

#Set-Alias g gvim
#$TransientScriptDir = "$here\scripts"
$UserBinDir = "$($home)\bin"

# PATH update
#
# creates paths to every subdirectory of userprofile\bin
# adds a transient script dir that I use for experiments
#$paths = @("$($env:Path)", $TransientScriptDir)
#Get-ChildItem $UserBinDir | ForEach-Object { $paths += $_.FullName }
#$env:Path = [String]::Join("; ", $paths) 
