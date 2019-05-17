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
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($initURL))

        if (test-path $home\.gitprofile\secrets.ps1) {
            & "$home\.gitprofile\secrets.ps1"
            Write-host -ForegroundColor Green "Running in online mode."
            Get-GitProfile $gitProfileURL > $env:LocalGitProfile
            return [scriptblock]::Create(
                [io.file]::ReadAllText($env:LocalGitProfile)
            )
        }
        else {
            return [scriptblock]::Create(
                (Get-GitProfile "https://raw.githubusercontent.com/$env:gitProfile/master/Git.PowerShell_profile.ps1").tostring()
            )
        }
    }
    else {
        Write-Host -foregroundcolor yellow "Running in offline mode."

        if (test-path $home\.gitprofile\secrets.ps1) {
            & "$home\.gitprofile\secrets.ps1" #using & instead of iex due to: https://paulcunningham.me/using-invoke-expression-with-spaces-in-paths/
            return  [scriptblock]::Create(
                [io.file]::ReadAllText($env:LocalGitProfile)
            )
        }
        else {
            return [scriptblock]::Create("Must be connected to run setup.")
        }
    }

}

. ( Update-GitProfile )