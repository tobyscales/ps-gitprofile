if (-not $env:gitProfile) { $env:gitProfile = "tobyscales/ps-gitprofile" }
if (-not $global:isConnected) { if ($PSVersionTable.PSVersion.Major -ge 6) { $global:isConnected = (test-connection "windows.net" -TCPPort 80 -quiet) } else { $global:isConnected = (Test-Connection 1.1.1.1 -count 1 -Quiet) } }
function Update-GitProfile {
    param([Parameter(ValueFromPipeline = $true)]
        [String[]]$gitProfile = $env:gitProfile)

    $getGitURL = "https://raw.githubusercontent.com/$gitProfile/master/functions/!required/Get-GitProfile.ps1"
    
    if ($global:isConnected) { 
        Write-host -ForegroundColor Green "Running in online mode... "
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($getGitURL))
        return [scriptblock]::Create(
            (Get-GitProfile "https://raw.githubusercontent.com/$env:gitProfile/master/Git.PowerShell_profile.ps1").tostring()
        )
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