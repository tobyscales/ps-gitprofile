if (-not $env:gitProfile) { $env:gitProfile = "tescales/ps-gitprofile" }

function Update-GitProfile {
    param([Parameter(ValueFromPipeline = $true)]
        [String[]]$gitProfile = $env:gitProfile)

    $initURL = "https://raw.githubusercontent.com/$gitProfile/master/functions/!required/Initialize-GitProfile.ps1"
    $gitProfileURL = "https://raw.githubusercontent.com/$gitProfile/master/Git.PowerShell_profile.ps1"

    #TODO: use runspaces for faster loading?
    #$runspaceURL = "https://raw.githubusercontent.com/pldmgg/misc-powershell/master/MyFunctions/PowerShellCore_Compatible/New-Runspace.ps1"
    #$runspaceURL = "https://raw.githubusercontent.com/RamblingCookieMonster/Invoke-Parallel/master/Invoke-Parallel/Invoke-Parallel.ps1"
    #Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($runspaceURL)) 

    #$ErrorActionPreference = 'SilentlyContinue'
    if (-not $isConnected) {
        if ($PSVersionTable.PSVersion.Major -ge 6) { $global:isConnected = (test-connection "windows.net" -TCPPort 80 -quiet) } else { $global:isConnected = (Test-Connection 1.1.1.1 -count 1 -Quiet) }
    }
    
    if ($global:isConnected) { 
        Write-host -ForegroundColor Green "Running in online mode."
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($initURL))

        if (test-path $home\.gitprofile\secrets.ps1) {
            & "$home\.gitprofile\secrets.ps1"
            Get-GitProfile $gitProfileURL > $env:LocalGitProfile
            return $true
        }
        else {
            # Non-persistent function loader
            $wr = Invoke-WebRequest -Uri "https://api.github.com/repos/$env:gitProfile/contents/functions/!required"
            $objects = $wr.Content | ConvertFrom-Json
            $files = $objects | where-object { $_.type -eq "file" } | Select-object -exp download_url
            
            foreach ($file in $files) {
                try {
                    #invoke-expression ((New-Object System.Net.WebClient).DownloadString($file)) -ErrorAction Stop
                    write-host -ForegroundColor Yellow "Loaded '$($file)'"
                }
                catch {
                    throw "Unable to download '$($file.path)'"
                }
            }
            return $false #(Initialize-GitProfile $gitProfile)
        }
    }
    else {
        Write-Host -foregroundcolor yellow "Running in offline mode."

        if (test-path $home\.gitprofile\secrets.ps1) {
            & "$home\.gitprofile\secrets.ps1" #using & instead of iex due to: https://paulcunningham.me/using-invoke-expression-with-spaces-in-paths/
            return $true    
        }
        else {
            write-host -ForegroundColor red "Must be connected to run setup."
            break;
        }
    }

}

if (Update-GitProfile) {
    #running in persisted mode
    . $env:LocalGitProfile 
}
else {
    . (
        [scriptblock]::Create(
            (Get-GitProfile "https://raw.githubusercontent.com/$env:gitProfile/master/Git.PowerShell_profile.ps1")
        )
    ) 
}    