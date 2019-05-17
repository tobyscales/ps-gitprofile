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
function which($name) { Get-Command $name | Select-Object Definition }
function rm-rf($item) { Remove-Item $item -Recurse -Force }
function touch($file) { "" | Out-File $file -Encoding ASCII }

function import-gFunction($name) {    
    $name=$name.tolower().trim()     
    write-host "downloading from https://raw.githubusercontent.com/$env:gitProfile/master/functions/$name.ps1"
    . (
        [scriptblock]::Create(
            (New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/$env:gitProfile/master/functions/$name.ps1")
        )
    ) 
}
function Mount-CloudShell {
    if ($global:isConnected) {
        switch ($true) {
            $isWindows {
                if (Get-PSDrive -name S) {
                    Write-Verbose "Found S:\ drive."
                    return "S:"
                }
                else {
                    $acctUser = $env:storagePath.split('.')[0]
                    $acctKey = ConvertTo-SecureString -String $env:storageKey -AsPlainText -Force
                    $credential = New-Object System.Management.Automation.PSCredential -ArgumentList "Azure\$acctUser", $acctKey

                    try {
                        New-PSDrive -Name S -PSProvider FileSystem -Root "\\$env:storagePath" -Credential $credential -Persist -Scope Global -ErrorAction Stop
                        Write-Verbose "Mapped drive \\$env:storagePath using $($credential.UserName)"
                        return "S:"
                    }
                    catch {
                        Write-Host -ForegroundColor Darkred "Error mapping cloudshell drive at $env:storagePath."
                        return split-path($env:LocalGitProfile).tostring()
                    }
                }                
            }
            $isLinux {
                if (Get-PSDrive -name "cloudshell" -ErrorAction SilentlyContinue) {
                    return "$home/cloudshell"
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
                            return split-path($env:LocalGitProfile).tostring()
                        }
                        Write-Verbose "Mapped drive \\$env:storagePath using $($credential.UserName)"
                        return "$home/cloudshell"
                    }
                    catch {
                        Write-Host -ForegroundColor Darkred "Error mapping cloudshell drive at $env:storagePath."
                        return split-path($env:LocalGitProfile).tostring()
                    }
                }                
            }
            $IsMacOS {
                Write-Host "Cloud Shell Mapping not yet enabled for MacOS, sorry."
                return split-path($env:LocalGitProfile).tostring()
            }
        }    
    }
    else { return $null }
}
#endregion functions

$here = (split-path $profile)
$isAdmin = $false

write-verbose "Loading $env:LocalGitProfile from $($MyInvocation.InvocationName)"

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

switch ($global:isConnected) {
    $true {
        $runspaceURL = "https://raw.githubusercontent.com/pldmgg/misc-powershell/master/MyFunctions/PowerShellCore_Compatible/New-Runspace.ps1"
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($runspaceURL)) 

        $getGFURL = "https://raw.githubusercontent.com/$env:gitProfile/master/functions/Get-GitFiles.ps1"
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($getGFURL))

        #env:LocalGitProfile means we're persisting a profile
        if ($env:LocalGitProfile) {
            
            #env:storageKey means we're persisting to cloudshell
            if ($env:storageKey) { $here = Mount-CloudShell; write-host "Mapped Cloud drive to $here." }

            write-host -ForegroundColor yellow "Loading required functions from $gitRepo..."
            $requiredPath = (join-path $here -childpath "functions" -AdditionalChildPath "!required")

            #Get-GitFiles -Owner $gitOwner -Repository $gitRepo -Path functions/!required -DestinationPath $requiredPath
            New-Runspace -runspacename "PS Clone" -scriptblock { Get-GitFiles -Owner $gitOwner -Repository $gitRepo -Path functions -DestinationPath "$here\functions" }
            New-Runspace -runspacename "PS Clone" -scriptblock { Get-GitFiles -Owner $gitOwner -Repository $gitRepo -Path Scripts -DestinationPath "$here\scripts" }
            
            foreach ($file in Get-ChildItem (join-path $requiredPath *.ps1) -recurse) {
                . (
                    [scriptblock]::Create(
                        [io.file]::ReadAllText($file)
                    )
                )
            }
        }
        else {
            # Non-persistent function loader
            $wr = Invoke-WebRequest -Uri "https://api.github.com/repos/$gitOwner/$gitRepo/contents/functions/!required"
            $objects = $wr.Content | ConvertFrom-Json
            $files = $objects | where-object { $_.type -eq "file" } | Select-object -exp download_url

            foreach ($file in $files) {
                try {
                    write-host -ForegroundColor Yellow "Loading '$($file)'"
                    invoke-expression ((New-Object System.Net.WebClient).DownloadString($file)) -ErrorAction Stop
                }
                catch {
                    throw "Unable to download '$($file.path)'"
                }
            }
        }
    }
    $false {
        $here = (split-path -$env:LocalGitProfile).tostring()
    }
}

write-host -ForegroundColor Yellow "Running Git.PowerShell from: $here"
set-location -Path "$here"

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
# if you want to add functions you can added scripts to your
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
 