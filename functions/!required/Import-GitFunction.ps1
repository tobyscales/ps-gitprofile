<#
##cribbed from https://gist.github.com/chrisbrownie/f20cb4508975fb7fb5da145d3d38024a 
.Synopsis
   This function will download a Github Repository without using Git
.DESCRIPTION
.EXAMPLE

#>
function global:Import-GitFunction {
    Param(
        [string]$Owner = (split-path ($env:gitProfile)),
        [string]$Repository = (split-path ($env:gitProfile) -leaf),
        [string]$FunctionName
    )
    write-host "Downloading function $FunctionName from https://raw.githubusercontent.com/$owner/$repository/master/functions/$FunctionName.ps1"
    . (
        [scriptblock]::Create(
            (New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/$owner/$repository/master/functions/$FunctionName.ps1")
            
        )
    )
}