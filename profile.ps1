if (-not $env:gitProfile) { $env:gitProfile = "tobyscales/ps-gitprofile" }
function Update-GitProfile {
    param([Parameter(ValueFromPipeline = $true)]
        [String[]]$gitProfile = $env:gitProfile)

    try {
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/tobyscales/ps-gitprofile/master/functions/!required/Get-GitProfile.ps1")) -ErrorAction Continue
        $global:isConnected = $true
        Write-host -ForegroundColor Green "Running in online mode."
        return [scriptblock]::Create(
            (Get-GitProfile "https://raw.githubusercontent.com/$gitProfile/master/Git.PowerShell_profile.ps1").tostring()
        )    
    }
    catch { 
        $global:isConnected = $false
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