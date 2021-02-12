if (-not $env:gitProfile) { $env:gitProfile = "tobyscales/ps-gitprofile" }
function Update-GitProfile {
    param([Parameter(ValueFromPipeline = $true)]
        [String[]]$gitProfile = $env:gitProfile)

    try {
        #Invoke-Expression ((New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/tobyscales/ps-gitprofile/master/functions/!required/Get-GitProfile.ps1")) -ErrorAction Continue
        $sb = [scriptblock]::Create(
            (New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/$gitProfile/master/Git.PowerShell_profile.ps1")
        )
        $global:isConnected = $true
        Write-host -ForegroundColor Green "Running in online mode."
    }
    catch { 
        $global:isConnected = $false
        Write-Host -ForegroundColor Yellow "Running in offline mode."
        if (-not $env:LocalGitProfile) {
            $sb = [scriptblock]::Create("Must be connected to run setup.") 
        }
        else {
            $sb = [scriptblock]::Create(
                [io.file]::ReadAllText($env:LocalGitProfile)
            )
        }    
    }
    return $sb
}
function global:Import-RequiredFunctions {
    param([Parameter( ValueFromPipeline = $true)]
        $gitProfile = $env:gitProfile)

    if (-not $env:localgitProfile) {
        # no profile stored, so load !required functions from github
        $wr = Invoke-WebRequest -Uri "https://api.github.com/repos/$gitProfile/contents/functions/!required"
        $objects = $wr.Content | ConvertFrom-Json
        $files = $objects | where-object { $_.type -eq "file" } | Select-object -exp download_url
                    
        foreach ($file in $files) {
            try {
                Write-Verbose "Loading $file from $env:gitProfile"
                invoke-expression ((New-Object System.Net.WebClient).DownloadString($file)) -ErrorAction Stop
            }
            catch {
                throw "Unable to download '$($file.path)'"
            }
        }
    } 
    else {
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
        [string]$gitProfile = $env:gitProfile
    )
    if (-not $functionName.endswith(".ps1")) { $functionName += ".ps1" }
    $wr = Invoke-WebRequest -Uri "https://api.github.com/repos/$gitProfile/contents/functions"
    
    $objects = $wr.Content | ConvertFrom-Json
    $url = $objects | where-object { $_.type -eq "file" -and $_.name.toUpper() -eq $functionName.toUpper() } | Select-object -exp download_url
    
    write-host "Importing $functionName from $url"
    invoke-expression ((New-Object System.Net.WebClient).DownloadString($url)) -ErrorAction Stop
    #$sb = [scriptblock]::Create((New-Object System.Net.WebClient).DownloadString($url))
    #$sb | iex
}
# function Get-GitProfile {
#     param([Parameter( Mandatory, ValueFromPipeline = $true)]
#         $gitProfileURL)
    
#     return (New-Object System.Net.WebClient).DownloadString($gitProfileURL)
# }
. ( Update-GitProfile )
global:Import-RequiredFunctions
Set-Alias igf global:Import-GitFunction
