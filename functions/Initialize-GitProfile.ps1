
function global:Set-GitProfile {
    param([Parameter( Mandatory, ValueFromPipeline = $true)]
        [String[]]$gitProfileURL)
        
    if (-not (test-path $profile)) { New-Item -ItemType File -Path $profile -Force  | Out-Null } 
    Get-GitProfile $gitProfileURL > $profile
}
function global:Get-GitProfile {
    param([Parameter( ValueFromPipeline = $true)]
        [String[]]$gitProfileURL)
    
    return (New-Object System.Net.WebClient).DownloadString($gitProfileURL)
}

function global:Initialize-GitProfile {
    param(
        [Parameter( Mandatory, 
            ValueFromPipeline = $true)]
        [String[]]$gitProfile)

    $configureMachine = ""
    #$useDefaultGitProfile = ""
    $useCloudShell = ""
    $gitProfileURL = "https://raw.githubusercontent.com/$gitProfile/master/Git.PowerShell_profile.ps1"
    $profileURL = "https://raw.githubusercontent.com/$gitProfile/master/profile.ps1"
    $invokeRFURL = "https://raw.githubusercontent.com/$gitProfile/master/functions/Invoke-RequiredFunctions.ps1"

    $envVars = @{ }

    while ("Y", "N" -notcontains $configureMachine.toUpper()) {
        $configureMachine = Read-Host "Would you like to configure this machine to always use `n--->$gitProfileURL`nas your PowerShell profile?"
        switch ($configureMachine.toUpper()) {
            "N" { 
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($invokeRFURL))
                #Invoke-RequiredFunctions -owner (split-path $gitProfile) -repository (split-path $gitProfile -leaf) -Path "functions/!required" 
                . (
                    [scriptblock]::Create(
                        (Get-GitProfile $gitProfileURL)
                    )
                )
                return $false
             }
            "Y" {
                Set-GitProfile $profileURL

                while ("Y", "N" -notcontains $useCloudShell.toUpper()) {
                    $useCloudShell = Read-Host "Would you like to use Azure Cloud Shell to store your PowerShell profile and functions?"
        
                    switch ($useCloudShell.toUpper()) {
                        "Y" {
                            $storageAcct = Read-Host -Prompt "Enter the storage account name for your cloud shell"
                            $storageShare = Read-Host -Prompt "Enter the share name for your cloud shell"
                            $storageKey = Read-Host -Prompt "Enter your Storage Account key"

                            #TODO: some better string validation
                            if ($storageAcct -notcontains "file.core.windows.net") { $storageAcct = "$storageAcct.file.core.windows.net" }

                            $envVars = [ordered]@{
                                '$env:gitProfile'      = "$gitProfile"
                                '$env:storagePath'     = "$storageAcct\$storageShare"
                                '$env:storageKey'      = $storageKey
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

                New-Item -ItemType File -Path "$home\.gitprofile\secrets.ps1" -Force  | Out-Null

                $columnWidth = $envVars.Keys.length | Sort-Object | Select-Object -Last 1
                $envVars.GetEnumerator() | ForEach-Object {
                    "{0,-$columnWidth}=`"{1}`"" -F $_.Key, $_.Value | out-file "$home\.gitprofile\secrets.ps1" -Append -Force
                }

                & "$home\.gitprofile\secrets.ps1" #using & instead of iex due to: https://paulcunningham.me/using-invoke-expression-with-spaces-in-paths/
                Get-GitProfile $gitProfileURL > $env:LocalGitProfile
                return $true
            }
            default { $configureMachine = Read-Host "Please enter Y or N" }
        }
    }
}
