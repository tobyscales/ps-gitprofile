
function global:Backup-CurrentProfile {
    $backupPath = join-path (split-path $profile) "backup"
    $backupProfileName = (split-path -leaf $profile)
    New-Item -ItemType Directory $backupPath -Force | out-null

    Get-ChildItem (split-path $profile) -exclude "backup" | Copy-Item -destination $backupPath -Recurse

    return (join-path $backupPath $backupProfileName)
}

function global:Uninstall-GitProfile {

    $backupPath = (join-path $here "backup")
    $functionPath = (join-path $here "functions")
    $scriptPath = (join-path $here "scripts")
    $removeAll = "" #bug on Linux PSCore
    
    #get previous PSProfile path
    if (-not $env:backupProfile) {
        $profileName = (split-path -leaf $profile)
        $backupProfileName = join-path $backupPath $profileName
    }
    else { $backupProfileName = $env:backupProfile }

    while ("Y", "N" -notcontains $removeAll.toUpper()) {
        $removeAll = Read-Host "This will restore your profile $backupProfileName and all files from $backupPath.`nIt will also remove all objects in these directories: `n-->$functionPath `n-->$scriptPath`n`n`nOK to proceed?"
        switch ($removeAll.toUpper()) {
            "Y" {
                Copy-Item $backupProfileName -destination $profile -Force
                Copy-Item $backupPath -destination "$(split-path($profile))" -Force -Recurse -Exclude '/backup'
                
                # #remove GitProfile objects
                # if ($env:LocalGitProfile) { $here = split-path($env:LocalGitProfile) } else { $here = split-path($profile) }
    
                Remove-Item -Path "$here\backup" -Recurse -Force 
                Remove-Item -Path "$here\functions" -Recurse -Force #-Confirm
                Remove-Item -Path "$here\scripts" -Recurse -Force #-Confirm

                Remove-Item -Path "$home\.gitprofile" -Recurse -force
                Remove-Item -Path $env:LocalGitProfile -force
                #Get-ChildItem -Directory $here | Remove-Item -Recurse
            }
            "N" {
                write-host "Operation cancelled."
            }
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
    #$invokeRFURL = "https://raw.githubusercontent.com/$gitProfile/master/functions/Invoke-RequiredFunctions.ps1"

    $envVars = @{ }

    while ("Y", "N" -notcontains $configureMachine.toUpper()) {
        $configureMachine = Read-Host "Always use `n--->$gitProfileURL`nas your PowerShell profile?`n(CAUTION: WILL OVERWRITE EXISTING PROFILE)"
        switch ($configureMachine.toUpper()) {
            "N" { 
                . global:Import-RequiredFunctions $gitProfile
                #Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($invokeRFURL))
                #Invoke-RequiredFunctions -owner (split-path $gitProfile) -repository (split-path $gitProfile -leaf) -Path "functions/!required" 
                
            }
            "Y" {
                $env:backupProfile = global:Backup-CurrentProfile

                Set-GitProfile $profileURL

                $envVars = [ordered]@{
                    '$env:gitProfile'      = "$gitProfile"
                    '$env:backupProfile'   = "$backupProfile"
                    '$env:LocalGitProfile' = join-path (split-path $profile) -childpath "Git.PowerShell_profile.ps1"
                }
                while ("Y", "N" -notcontains $useCloudShell.toUpper()) {
                    $useCloudShell = Read-Host "Would you like to automatically mount your Azure Cloud Shell drive?"
        
                    switch ($useCloudShell.toUpper()) {
                        "Y" {
                            $storageAcct = Read-Host -Prompt "Enter the storage account name for your cloud shell"
                            $storageShare = Read-Host -Prompt "Enter the share name for your cloud shell"
                            $storageKey = Read-Host -Prompt "Enter your Storage Account key"

                            #TODO: some better string validation
                            if ($storageAcct -notcontains "file.core.windows.net") { $storageAcct = "$storageAcct.file.core.windows.net" }

                            $envVars += [ordered]@{
                                '$env:storagePath'     = "$storageAcct\$storageShare"
                                '$env:storageKey'      = $storageKey
                                #TODO: put cloudshell into path or alias to 
                            }
                        }
                        "N" { 

                        }
                        default { $useCloudShell = Read-Host "Please enter Y or N" }
                    }
                }

                #New-Item -ItemType File -Path "$home\.gitprofile\secrets.ps1" -Force | Out-Null

                $columnWidth = $envVars.Keys.length | Sort-Object | Select-Object -Last 1
                $envVars.GetEnumerator() | ForEach-Object {
                    "{0,-$columnWidth}=`"{1}`"" -F $_.Key, $_.Value | out-file "$profile" -Append -Force
                }

                #& "$home\.gitprofile\secrets.ps1" #using & instead of iex due to: https://paulcunningham.me/using-invoke-expression-with-spaces-in-paths/
                Get-GitProfile $gitProfileURL > $env:LocalGitProfile
                . $env:LocalGitProfile
            }
            default { $configureMachine = Read-Host "Please enter Y or N" }
        }
    }
}
