<#
##cribbed from https://gist.github.com/chrisbrownie/f20cb4508975fb7fb5da145d3d38024a 
.Synopsis
   This function will download a Github Repository without using Git
.DESCRIPTION
.EXAMPLE

#>
function global:Import-GitFunction {
    Param(
        [string]$functionName
    )
    
    write-host "Downloading function $functionName from https://raw.githubusercontent.com/$env:gitProfile/master/functions/$functionName.ps1"
    . (
        [scriptblock]::Create(
            (New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/$env:gitProfile/master/functions/$functionName.ps1")
            
        )
    )
}