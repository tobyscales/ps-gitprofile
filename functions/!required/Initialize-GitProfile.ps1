
function global:Set-GitProfile {
    param([Parameter( Mandatory, ValueFromPipeline = $true)]
        [String[]]$gitProfileURL)
        
    if (-not (test-path $profile)) { New-Item -ItemType File -Path $profile -Force | Out-Null } 
    Get-GitProfile $gitProfileURL > $profile
}
function global:Get-GitProfile {
    param([Parameter( ValueFromPipeline = $true)]
        [String[]]$gitProfileURL)
    
    return (New-Object System.Net.WebClient).DownloadString($gitProfileURL)
}
function global:Backup-CurrentProfile {
    $backupPath = join-path (split-path $profile) "backup"
    $backupProfile = (split-path -leaf $profile)
    New-Item -ItemType Directory $backupPath -Force | out-null
    Copy-Item $profile -destination (join-path $backupPath $backupProfile)
    return (join-path $backupPath $backupProfile)
}

function global:Uninstall-GitProfile {

    #remove GitProfile objects
    if ($env:LocalGitProfile) { $here = split-path($env:LocalGitProfile) } else { $here = split-path($profile) }

    Remove-Item -Path "$here" -Recurse -force
    Remove-Item -Path "$home\.gitprofile" -Recurse -force
    Remove-Item -Path $env:LocalGitProfile -force

    #restore previous PSProfile
    if (-not $env:backupProfile) {
        $backupPath = join-path (split-path $profile) "backup"
    } else { $backupPath = $env:backupProfile}

    Copy-Item $backupPath -destination $profile -Force
    write-host ""
    while ("Y", "N" -notcontains $configureMachine.toUpper()) {
        $okToRestore = Read-Host "Restored from $backupPath.`nOK to remove backup directory?"
        switch ($okToRestore.toUpper()) {
            "Y" { Remove-Item -Path (split-path $backupPath) -Recurse -force }
            "N" { }
        }
    }
}

function global:Initialize-GitProfile {
    param(
        [Parameter(  
            ValueFromPipeline = $true)]
        [String[]]$gitProfile = $env:gitProfile)

    $configureMachine = ""
    $useCloudShell = ""
    $gitProfileURL = "https://raw.githubusercontent.com/$gitProfile/master/Git.PowerShell_profile.ps1"
    $profileURL = "https://raw.githubusercontent.com/$gitProfile/master/profile.ps1"
    $invokeRFURL = "https://raw.githubusercontent.com/$gitProfile/master/functions/Invoke-RequiredFunctions.ps1"

    $envVars = @{ }

    while ("Y", "N" -notcontains $configureMachine.toUpper()) {
        $configureMachine = Read-Host "Always use `n--->$gitProfileURL`nas your PowerShell profile?`n(CAUTION: WILL OVERWRITE EXISTING PROFILE)"
        switch ($configureMachine.toUpper()) {
            "N" { 
                
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($invokeRFURL))
                #Invoke-RequiredFunctions -owner (split-path $gitProfile) -repository (split-path $gitProfile -leaf) -Path "functions/!required" 
                
            }
            "Y" {
                $env:backupProfile = global:Backup-CurrentProfile

                Set-GitProfile $profileURL

                while ("Y", "N" -notcontains $useCloudShell.toUpper()) {
                    $useCloudShell = Read-Host "Would you like to automatically map your Azure Cloud Shell drive?"
        
                    switch ($useCloudShell.toUpper()) {
                        "Y" {
                            $storageAcct = Read-Host -Prompt "Enter the storage account name for your cloud shell"
                            $storageShare = Read-Host -Prompt "Enter the share name for your cloud shell"
                            $storageKey = Read-Host -Prompt "Enter your Storage Account key"

                            #TODO: some better string validation
                            if ($storageAcct -notcontains "file.core.windows.net") { $storageAcct = "$storageAcct.file.core.windows.net" }

                            $envVars = [ordered]@{
                                '$env:gitProfile'      = "$gitProfile"
                                '$env:backupProfile'   = "$backupProfile"
                                '$env:storagePath'     = "$storageAcct\$storageShare"
                                '$env:storageKey'      = $storageKey
                                #TODO: put cloudshell into path or alias to 
                                '$env:LocalGitProfile' = join-path (split-path $profile) -childpath "Git.PowerShell_profile.ps1"
                            }
                        }
                        "N" { 
                            $envVars = [ordered]@{
                                '$env:gitProfile'      = "$gitProfile"
                                '$env:LocalGitProfile' = join-path (split-path $profile) -childpath "Git.PowerShell_profile.ps1"
                            }
                        }
                        default { $useCloudShell = Read-Host "Please enter Y or N" }
                    }
                }

                New-Item -ItemType File -Path "$home\.gitprofile\secrets.ps1" -Force | Out-Null

                $columnWidth = $envVars.Keys.length | Sort-Object | Select-Object -Last 1
                $envVars.GetEnumerator() | ForEach-Object {
                    "{0,-$columnWidth}=`"{1}`"" -F $_.Key, $_.Value | out-file "$home\.gitprofile\secrets.ps1" -Append -Force
                }

                & "$home\.gitprofile\secrets.ps1" #using & instead of iex due to: https://paulcunningham.me/using-invoke-expression-with-spaces-in-paths/
                Get-GitProfile $gitProfileURL > $env:LocalGitProfile
                . $env:LocalGitProfile
            }
            default { $configureMachine = Read-Host "Please enter Y or N" }
        }
    }
}
