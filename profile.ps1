if (-not ($env:gitProfile)) { $env:gitProfile = "tobyscales/ps-gitprofile" }
if (-not ($env:localGitProfile)) { $global:isTransientProfile = $true }

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
        if ($env:LocalGitProfile) {
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

    $gitProfile = $env:gitProfile

    switch ($useOnlineOnly) {
        $true {
            # no profile stored, so load !required functions from github
            $wr = Invoke-WebRequest -usebasicparsing -Uri "https://api.github.com/repos/$gitProfile/contents/functions/!required"
            $objects = $wr.Content | ConvertFrom-Json
            $urls = $objects | where-object { $_.type -eq "file" } | Select-object -exp download_url
                    
            foreach ($url in $urls) {
                try {
                    Write-Host "Loading " -NoNewline -ForegroundColor Green
                    write-host "$($url.split('/')[-1])" -NoNewline -ForegroundColor White
                    write-host " from " -ForegroundColor Green -NoNewLine
                    write-host $gitProfile -ForegroundColor White -NoNewLine
                    write-host "..." -ForegroundColor Green
                    Write-Verbose "Running online, so loading $url from $gitProfile"
                    (New-Object System.Net.WebClient).DownloadString("$url") | Invoke-Expression
                }
                catch {
                    throw "Unable to download '$($url.path)'"
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

    $wr = Invoke-WebRequest -usebasicparsing -Uri "https://api.github.com/repos/$gitProfile/contents/$subPath"
    $objects = $wr.Content | ConvertFrom-Json
    $url = $objects | where-object { $_.type -eq "file" -and $_.name.toUpper() -eq $functionName.toUpper() } | Select-object -exp download_url

    write-host "Importing $functionName from $url"
    (New-Object System.Net.WebClient).DownloadString($url) | Invoke-Expression 
}
. ( Update-GitProfile )                                 #executes Git.Powershell_Profile from GH or from local cache, if installed and offline
Import-RequiredFunctions $isTransientProfile            #imports !required functions from GH (transient) or all /functions from local cache (installed)
Set-Alias igf global:Import-GitFunction                 #enables alias for easy importing of functions from a GH profile

