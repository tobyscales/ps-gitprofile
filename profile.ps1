if (-not ($env:gitProfile)) { $env:gitProfile = "tobyscales/ps-gitprofile" } ##TODO: fix up use of env vars, use global where appropriate
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

    if ($useOnlineOnly) {
            # no profile stored, so load !required functions from github
            $wr = Invoke-WebRequest -usebasicparsing -Uri "https://api.github.com/repos/$gitProfile/contents/functions/!required"
            $objects = $wr.Content | ConvertFrom-Json
            $urls = $objects | where-object { $_.type -eq "file" } | Select-object -exp download_url
                    
            foreach ($url in $urls) {
                try {
                    Write-Host "Loading " -NoNewline -ForegroundColor Yellow
                    write-host "$($url.split('/')[-1])" -ForegroundColor White -NoNewline
                    write-host " from " -ForegroundColor Yellow -NoNewLine
                    write-host "$gitProfile..." -ForegroundColor White
                    Write-Verbose "Loading $url from $gitProfile"
                    invoke-expression ((New-Object System.Net.WebClient).DownloadString($url)) -ErrorAction Stop
                }
                catch {
                    throw "Unable to download '$($url.path)'"
                }
            }
        } else {
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
function global:Import-GitFunction {
    Param(
        [string]$functionName,
        [string]$gitProfile = $env:gitProfile,
        [string]$subPath = "functions"
    )
    if (-not $functionName.endswith(".ps1")) { $functionName += ".ps1" }

    #add test-local logic to import-gitfunction, a la if (test-path "$here\functions\get-gitfiles.ps1") { }
    $wr = Invoke-WebRequest -usebasicparsing -Uri "https://api.github.com/repos/$gitProfile/contents/$subPath"
    $objects = $wr.Content | ConvertFrom-Json
    $url = $objects | where-object { $_.type -eq "file" -and $_.name.toUpper() -eq $functionName.toUpper() } | Select-object -exp download_url

    Write-Host "Loading " -NoNewline -ForegroundColor Yellow
    write-host "$functionName" -ForegroundColor White -NoNewline
    write-host " from " -ForegroundColor Yellow -NoNewline
    write-host "$gitProfile" -ForegroundColor white
    (New-Object System.Net.WebClient).DownloadString($url) | Invoke-Expression 
}
. ( Update-GitProfile )                                 #executes Git.Powershell_Profile from GH or from local cache, if installed and offline
. Import-RequiredFunctions $isTransientProfile          #imports !required functions from GH (transient) or all /functions from local cache (installed)
Set-Alias igf global:Import-GitFunction                 #enables alias for easy importing of functions from a GH profile

