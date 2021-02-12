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
        [string]$DestinationPath,
        [string]$ExcludePath = ""
    )

    if (-not (Test-Path $DestinationPath)) {
        # Destination path does not exist, let's create it
        try {
            New-Item -Path $DestinationPath -ItemType Directory -ErrorAction Stop | Out-Null
        }
        catch {
            throw "Could not create path '$DestinationPath'!"
        }
    }

    if (-not (Get-Command -ErrorAction SilentlyContinue git)) {
        $baseUri = "https://api.github.com/"
        $paths = "repos/$Owner/$Repository/contents/$Path"
        $wr = Invoke-WebRequest -Uri $($baseuri + $paths)
        $objects = $wr.Content | ConvertFrom-Json
        $files = $objects | Where-Object { $_.type -eq "file" } | Select-Object -exp download_url
        $directories = $objects | Where-Object { $_.type -eq "dir" }
        
        $directories | ForEach-Object { 
            #if ($_.name -ne $ExcludePath) {
            Get-GitFiles -Owner $Owner -Repository $Repository -Path $_.path -DestinationPath (join-path $DestinationPath -childpath $_.name)
            #}
        }
    
        foreach ($file in $files) {
            $fileDestination = Join-Path $DestinationPath (Split-Path $file -Leaf)
            try {
                write-verbose "Saving file $file to $fileDestination..."
                Invoke-WebRequest -Uri $file -OutFile $fileDestination -ErrorAction Stop 
            }
            catch {
                throw "Unable to download '$($file.path)'"
            }
        }
    } #no git installed; cribbed from https://en.terminalroot.com.br/how-to-clone-only-a-subdirectory-with-git-or-svn/
    else {
        & cd $DestinationPath
        & git init
        & git remote add -f origin https://github.com/$Owner/$Repository
        & git config core.sparseCheckout true
        & echo $Path >> .git/info/sparse-checkout
        & echo $ExcludePath >> .git/info/sparse-checkout
        & git pull origin master
    }
}