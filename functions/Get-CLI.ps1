<#
.Synopsis
   This function will download the specified OSS binary, for the platform you happen to be running on
.DESCRIPTION

.EXAMPLE
    Get-CLI terraform
    #TODO: Get-CLI helm -version 3
    Get-CLI vagrant C:\scripts\bin

#>
function Get-CLI {
    Param(
        [string]$toolName,
        [string]$fileDestination = "$here\CLI"
    )

    if (-not (test-path $fileDestination)) { New-Item -itemType Directory -Path $fileDestination }
    $toolName = $toolName.ToLower()

    if ($isWindows) {$destFile="$fileDestination\$toolName.exe"} else {$destFile="$fileDestination\$toolName"}

    if (test-path $destFile) { 
        write-host $toolname -foregroundcolor Yellow -nonewline
        write-host " already exists at $fileDestination." -foregroundcolor Red 
        Write-Host "Will update PATH."
    }
    else {
        # set Hashi tools
        $hashiCorpTools = @('terraform', 'vault', 'consul', 'packer', 'vagrant')

        # set processor architecture
        if ($env:PROCESSOR_ARCHITECTURE -ne "AMD64") {
            ## TODO: add 32-bit support
        }
        else { 
            $arch = "amd64"
        }

        # set current host OS
        switch ($true) {
            $isMacOS { $platform = "darwin" }
            $IsWindows { $platform = "windows" }
            $IsLinux { $platform = "linux" }
            Default {
                return "No platform found."
            }
        }

        if ($hashiCorpTools -contains $toolName) { 
            $version = ((invoke-webrequest -usebasicparsing "https://checkpoint-api.hashicorp.com/v1/check/$toolName").content | ConvertFrom-Json).current_version
            $url = "https://releases.hashicorp.com/$toolName/$version/${toolName}_${version}_${platform}_${arch}.zip"
            write-host $url
        }
        else {
            switch ($toolName) {
                "kubectl" {
                    $version = (Invoke-WebRequest -UseBasicParsing "https://dl.k8s.io/release/stable.txt").Content
                    $url = "https://dl.k8s.io/release/$version/bin/$platform/$arch/kubectl" 
                }
                "helm" {
                    $version = split-path -leaf (((Invoke-WebRequest -UseBasicParsing "https://github.com/helm/helm/releases").Content | Select-string -pattern "(?smi)/helm/helm/releases/tag/v3.[0-9]*.[0-9]*").Matches.Groups[0].Value)
                    if ($isWindows) { $url = "https://get.helm.sh/helm-$version-$platform-$arch.zip" } else { $url = "https://get.helm.sh/helm-$version-$platform-$arch.tar.gz" }
                }
                Default {}
            }
        }

        #download/expand
        Write-Verbose "Installing $toolName from $url..."

        try {
            write-host "Saving latest version of " -foregroundcolor Green -NoNewline
            write-host "$toolName" -ForegroundColor Yellow -NoNewline
            Write-Host " to " -ForegroundColor Green -NoNewline
            write-host "$fileDestination..." 

            $tempFile = "$fileDestination\" + (split-path -leaf $url)
            Invoke-WebRequest -usebasicparsing -Uri $url -OutFile $tempFile -ErrorAction Stop 
        }
        catch {
            throw "Unable to download '$url'"
        }

        Expand-Archive -Path $tempFile -DestinationPath $fileDestination
        Remove-Item -Path $tempFile
    }

    #update PATH
    # creates paths for every subdirectory of specified destination, in case extraction resulted in a subdir
    $paths = @("$($env:Path)", $fileDestination)
    Get-ChildItem $fileDestination | select-object -Property Directory | ForEach-Object { $paths += $_.FullName }
    $env:Path = [String]::Join("; ", $paths) 
      
}