
function global:Import-GitFunction {
    Param(
        [string]$functionName
    )
    #TODO: add case-insensitivity
    write-host "Downloading function $functionName from https://raw.githubusercontent.com/$env:gitProfile/master/functions/$functionName.ps1"
    . (
        [scriptblock]::Create(
            (New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/$env:gitProfile/master/functions/$functionName.ps1")
            
        )
    )
}
Set-Alias igf global:Import-GitFunction
