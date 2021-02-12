function global:Import-GitFunction {
    Param(
        [string]$functionName,
        [string]$gitProfile = $env:gitProfile
    )
    if (-not $functionName.endswith(".ps1")) { $functionName += ".ps1"}
    $wr = Invoke-WebRequest -Uri "https://api.github.com/repos/$gitProfile/contents/functions"
    
    $objects = $wr.Content | ConvertFrom-Json
    $url = $objects | where-object { $_.type -eq "file" -and $_.name.toUpper() -eq $functionName.toUpper() } | Select-object -exp download_url
    
    write-host "Importing $functionName from $url"
    #invoke-expression ((New-Object System.Net.WebClient).DownloadString($url)) -ErrorAction Stop
    $sb = [scriptblock]::Create((New-Object System.Net.WebClient).DownloadString($url))
    $sb | iex
}
Set-Alias igf global:Import-GitFunction
