function global:Backup-CurrentProfile {
    $backupPath = join-path (split-path $profile) "backup"
    $backupProfileName = (split-path -leaf $profile)
    New-Item -ItemType Directory $backupPath -Force | out-null

    Get-ChildItem (split-path $profile) -exclude 'backup' | Copy-Item -destination $backupPath -Recurse

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
        $removeAll = Read-Host "This will restore your profile $backupProfileName and all files from $backupPath.`nIt will also remove all objects in these directories: `n-->$functionPath `n-->$scriptPath`n`nOK to proceed?"
        switch ($removeAll.toUpper()) {
            "Y" {
                Copy-Item $backupProfileName -destination $profile -Force
                Copy-Item $backupPath -destination "$(split-path($profile))" -Force -Recurse -Exclude 'backup' -whatif
                
                Remove-Item -Path "$here\backup" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "$here\functions" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "$here\scripts" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "$here\.git" -Recurse -Force -ErrorAction SilentlyContinue

                Remove-Item -Path $env:LocalGitProfile -force -ErrorAction SilentlyContinue
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

    $envVars = @{ }

    while ("Y", "N" -notcontains $configureMachine.toUpper()) {
        $configureMachine = Read-Host "This will permanently set your PowerShell profile to:`n  --->$gitProfileURL`n(Run Uninstall-GitProfile to revert changes.)`n`nOK to proceed?"
        switch ($configureMachine.toUpper()) {
            "Y" {
                $env:backupProfile = global:Backup-CurrentProfile

                #if (-not (test-path $profile)) { New-Item -ItemType File -Path $profile -Force | Out-Null } 
                (New-Object System.Net.WebClient).DownloadString($profileURL) > $profile

                $env:gitProfile      = "$gitProfile"
                $env:backupProfile   = "$backupProfile"
                $env:LocalGitProfile = join-path (split-path $profile) -childpath "Git.PowerShell_profile.ps1"

                #persist the values in profile
                $envVars = [ordered]@{
                '$env:gitProfile'      = "$gitProfile"
                '$env:backupProfile'   = "$backupProfile"
                '$env:LocalGitProfile' = join-path (split-path $profile) -childpath "Git.PowerShell_profile.ps1"
                }
                while ("Y", "N" -notcontains $useCloudShell.toUpper()) {
                    $useCloudShell = Read-Host "Would you like to automatically mount your Azure Cloud Shell drive?`n(WARNING: Will save Storage Key in plaintext to your profile.)"
        
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
                                #TODO: put cloudshell into path, or at least alias to it?
                            }
                        }
                        "N" { }
                        default { $useCloudShell = Read-Host "Please enter Y or N" }
                    }
                }

                $columnWidth = $envVars.Keys.length | Sort-Object | Select-Object -Last 1
                $envVars.GetEnumerator() | ForEach-Object {
                    "{0,-$columnWidth}=`"{1}`"" -F $_.Key, $_.Value + '\n' + (get-content $profile) | set-content "$profile" -Force
                }

                (New-Object System.Net.WebClient).DownloadString($gitProfileURL) > $env:LocalGitProfile
                . $env:LocalGitProfile
            }
            "N" { }
            default { $configureMachine = Read-Host "Please enter Y or N" }
        }
    }
    
}