if (-not $env:gitProfile) { $env:gitProfile = "tobyscales/ps-gitprofile" }
if (-not $global:isConnected) { if ($PSVersionTable.PSVersion.Major -ge 6) { $global:isConnected = (test-connection "1.1.1.1" -TCPPort 53 -quiet) } else { $global:isConnected = (Test-Connection 1.1.1.1 -count 1 -Quiet) } }
function Update-GitProfile {
    param([Parameter(ValueFromPipeline = $true)]
        [String[]]$gitProfile = $env:gitProfile)

    if ($global:isConnected) { 
        Write-host -ForegroundColor Green "Running in online mode."
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/tobyscales/ps-gitprofile/master/functions/!required/Get-GitProfile.ps1"))
        return [scriptblock]::Create(
            (Get-GitProfile "https://raw.githubusercontent.com/$gitProfile/master/Git.PowerShell_profile.ps1").tostring()
        )
    }
    else {
        Write-Host -ForegroundColor Yellow "Running in offline mode."

        if (-not $env:LocalGitProfile) {
            return [scriptblock]::Create("Must be connected to run setup.") 
        }
        else {
            return  [scriptblock]::Create(
                [io.file]::ReadAllText($env:LocalGitProfile)
            )
        }    
    }

}

. ( Update-GitProfile )