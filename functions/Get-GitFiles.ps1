<#
##cribbed from https://gist.github.com/chrisbrownie/f20cb4508975fb7fb5da145d3d38024a 
.Synopsis
   This function will download a Github Repository without using Git
.DESCRIPTION
.EXAMPLE

#>
function Get-GitFiles {
    Param(
        [string]$Owner,
        [string]$Repository,
        [string]$Path,
        [string]$DestinationPath
        )
    
        $baseUri = "https://api.github.com/"
        $args = "repos/$Owner/$Repository/contents/$Path"
        $wr = Invoke-WebRequest -Uri $($baseuri+$args)
        $objects = $wr.Content | ConvertFrom-Json
        $files = $objects | where {$_.type -eq "file"} | Select -exp download_url
        $directories = $objects | where {$_.type -eq "dir"}
        
        $directories | ForEach-Object { 
            #if ($_.name -ne "!required") {
            Get-GitFiles -Owner $Owner -Repository $Repository -Path $_.path -DestinationPath (join-path $DestinationPath -childpath $_.name)
            #}
        }
    
        
        if (-not (Test-Path $DestinationPath)) {
            # Destination path does not exist, let's create it
            try {
                New-Item -Path $DestinationPath -ItemType Directory -ErrorAction Stop | Out-Null
            } catch {
                throw "Could not create path '$DestinationPath'!"
            }
        }
    
        foreach ($file in $files) {
            $fileDestination = Join-Path $DestinationPath (Split-Path $file -Leaf)
            try {
                write-verbose "Saving file $file to $fileDestination..."
                Invoke-WebRequest -Uri $file -OutFile $fileDestination -ErrorAction Stop 
            } catch {
                throw "Unable to download '$($file.path)'"
            }
        }
    
    }