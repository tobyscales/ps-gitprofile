if (-not $env:gitProfile) { $env:gitProfile = "tescales/ps-gitprofile" }
function global:Update-GitProfile {
    param([Parameter( Mandatory, ValueFromPipeline = $true)]
        [String[]]$gitProfile)

    $initURL = "https://raw.githubusercontent.com/$gitProfile/master/functions/Initialize-GitProfile.ps1"
    $gitProfileURL = "https://raw.githubusercontent.com/$gitProfile/master/Git.PowerShell_profile.ps1"

    #TODO: use runspaces for faster loading?
    #$runspaceURL = "https://raw.githubusercontent.com/pldmgg/misc-powershell/master/MyFunctions/PowerShellCore_Compatible/New-Runspace.ps1"
    #$runspaceURL = "https://raw.githubusercontent.com/RamblingCookieMonster/Invoke-Parallel/master/Invoke-Parallel/Invoke-Parallel.ps1"
    #Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($runspaceURL)) 

    #$ErrorActionPreference = 'SilentlyContinue'
    if ($PSVersionTable.PSVersion.Major -ge 6) { $env:isConnected = (test-connection "windows.net" -TCPPort 80 -quiet) } else { $env:isConnected = (Test-Connection 1.1.1.1 -count 1 -Quiet) }
    write-host "MyInvocation"
    $MyInvocation | fl

    if ($env:isConnected) { 
        Write-host -ForegroundColor Green "Connection detected."
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($initURL))

        if (-not (test-path $home\.gitprofile\secrets.ps1)) {
            Initialize-GitProfile $gitProfile
        }
        else {
            & "$home\.gitprofile\secrets.ps1"
            Get-GitProfile $gitProfileURL > $env:LocalGitProfile
            Invoke-Expression $env:LocalGitProfile
        }
    }
    else {
        Write-Host -foregroundcolor yellow "Running in offline mode."

        if (-not (test-path $home\.gitprofile\secrets.ps1)) {
            write-host -ForegroundColor red "Must be connected to run setup."
        }

        & "$home\.gitprofile\secrets.ps1" #using & instead of iex due to: https://paulcunningham.me/using-invoke-expression-with-spaces-in-paths/
        Invoke-Expression $env:LocalGitProfile
    }
}

Update-GitProfile $env:gitProfile 