<#
##cribbed from https://gist.github.com/chrisbrownie/f20cb4508975fb7fb5da145d3d38024a 
.Synopsis
   This function will download a Github Repository without using Git
.DESCRIPTION
.EXAMPLE

#>
function Invoke-RequiredFunctions {
    Param(
        [string]$gitProfile,
        [string]$Path
        )
    
        $baseUri = "https://api.github.com/"
        $args = "repos/$gitProfile/contents/$Path"
        $wr = Invoke-WebRequest -Uri $($baseuri+$args)
        $objects = $wr.Content | ConvertFrom-Json
        $files = $objects | Where-Object {$_.type -eq "file"} | Select-object -exp download_url
        $directories = $objects | Where-Object {$_.type -eq "dir"}
        
        $directories | ForEach-Object { 
            Invoke-RequiredFunctions -gitProfile $gitProfile -Path $_.path
        }
    
        foreach ($file in $files) {
            try {
                invoke-expression ((New-Object System.Net.WebClient).DownloadString($file)) -ErrorAction Stop 
                "Loaded '$($file)'"
            } catch {
                throw "Unable to download '$($file.path)'"
            }
        }
    
    }