<#
##cribbed from https://gist.github.com/chrisbrownie/f20cb4508975fb7fb5da145d3d38024a 
.Synopsis
   This function will download a Github Repository without using Git
.DESCRIPTION
.EXAMPLE

#>
function global:Import-GitFunction {
    Param(
        [string]$Owner,
        [string]$Repository,
        [string]$FunctionName
    )
    
    $wr = Invoke-WebRequest -Uri "https://api.github.com/repos/$Owner/$Repository/contents/functions"
    $objects = $wr.Content | ConvertFrom-Json
    $files = $objects | where-object { $_.type -eq "file" } | Select-object -exp download_url
    
    foreach ($file in $files) {
        if ((split-path $file -leaf) -eq "$FunctionName.ps1") {
            try {
                invoke-expression ((New-Object System.Net.WebClient).DownloadString($file)) -ErrorAction Stop
                "Loaded '$file'"
            }
            catch {
                throw "Unable to download '$file'"
            }
        }
    }
    
}