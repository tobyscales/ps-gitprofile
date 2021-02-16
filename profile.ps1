if (-not (test-path($env:gitProfile))) { $env:gitProfile = "tobyscales/ps-gitprofile" }
if (-not (test-path($env:localGitProfile))) { $global:isTransientProfile = $true }

function Update-GitProfile {
    param([Parameter(ValueFromPipeline = $true)]
        [String[]]$gitProfile = $env:gitProfile)

    try {
        $sb = [scriptblock]::Create(
            (New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/$gitProfile/master/Git.PowerShell_profile.ps1")
        )
        #testing only $sb = [scriptblock]::Create([io.file]::ReadAllText($env:LocalGitProfile))
        $global:isConnected = $true
        Write-host -ForegroundColor Green "Online mode."
    }
    catch { 
        $global:isConnected = $false
        Write-Host -ForegroundColor Yellow "Offline mode."
        if (test-path($env:LocalGitProfile)) {
            $sb = [scriptblock]::Create(
                [io.file]::ReadAllText($env:LocalGitProfile)
            )            
        }
        else {
            $sb = [scriptblock]::Create("write-host ""Must be connected to run setup.""") 
        }    
    }
    return $sb
}
function global:Import-RequiredFunctions {
    param([Parameter( ValueFromPipeline = $true)]$useOnlineOnly)

    switch ($useOnlineOnly) {
        $true {
            # no profile stored, so load !required functions from github
            $wr = Invoke-WebRequest -Uri "https://api.github.com/repos/$gitProfile/contents/functions/!required"
            $objects = $wr.Content | ConvertFrom-Json
            $urls = $objects | where-object { $_.type -eq "file" } | Select-object -exp download_url
                    
            foreach ($url in $urls) {
                try {
                    Write-Verbose "Loading $file from $env:gitProfile"
                    invoke-expression ((New-Object System.Net.WebClient).DownloadString($file)) -ErrorAction Stop
                }
                catch {
                    throw "Unable to download '$($file.path)'"
                }
            }
        }
        $false {
            $functionpath = (join-path $here -childpath "functions")
            foreach ($file in Get-ChildItem (join-path $functionpath *.ps1) -recurse) {
                . (
                    [scriptblock]::Create(
                        [io.file]::ReadAllText($file)
                    )
                )
            }
        } 
    }
}
function global:Import-GitFunction {
    Param(
        [string]$functionName,
        [string]$gitProfile = $env:gitProfile,
        [string]$subPath = "functions"
    )
    if (-not $functionName.endswith(".ps1")) { $functionName += ".ps1" }

    $wr = Invoke-WebRequest -Uri "https://api.github.com/repos/$gitProfile/contents/$subPath"
    $objects = $wr.Content | ConvertFrom-Json
    $url = $objects | where-object { $_.type -eq "file" -and $_.name.toUpper() -eq $functionName.toUpper() } | Select-object -exp download_url

    write-host "Importing $functionName from $url"
    (New-Object System.Net.WebClient).DownloadString($url) | Invoke-Expression 
}
. ( Update-GitProfile )                                 #executes Git.Powershell_Profile from GH or from local cache, if installed and offline
Import-RequiredFunctions $global:isTransientProfile     #imports !required functions from GH (transient) or all /functions from local cache, if installed
Set-Alias igf global:Import-GitFunction                 #enables alias for easy importing of functions from a GH profile

