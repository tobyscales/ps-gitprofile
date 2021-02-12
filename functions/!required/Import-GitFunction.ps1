function global:Import-LocalFunctions {
    $functionpath = (join-path $here -childpath "functions")
    New-Item -ItemType Directory $functionpath -Force | Out-Null

    foreach ($file in Get-ChildItem (join-path $functionpath *.ps1) -recurse) {
        . (
            [scriptblock]::Create(
                [io.file]::ReadAllText($file)
            )
        )
    }
}
function global:Import-GitFunction {
    Param(
        [string]$functionName
    )
    if (-not $functionName.endswith(".ps1")) { $functionName += ".ps1"}
    $wr = Invoke-WebRequest -Uri "https://api.github.com/repos/$gitProfile/contents/functions"
    
    $objects = $wr.Content | ConvertFrom-Json
    $url = $objects | where-object { $_.type -eq "file" -and $_.name.toUpper() -eq $functionName.toUpper() } | Select-object -exp download_url
    
    write-host "Downloading function $functionName from $url"
    #invoke-expression ((New-Object System.Net.WebClient).DownloadString($url)) -ErrorAction Stop
    . [scriptblock]::Create((New-Object System.Net.WebClient).DownloadString($url))
}
Set-Alias igf global:Import-GitFunction
Set-Alias ilf global:Import-LocalFunctions