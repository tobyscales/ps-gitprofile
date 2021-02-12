# function global:Set-GitProfile {
#     param([Parameter( Mandatory, ValueFromPipeline = $true)]
#         $gitProfileURL)
        
#     if (-not (test-path $profile)) { New-Item -ItemType File -Path $profile -Force | Out-Null } 
#     Get-GitProfile $gitProfileURL > $profile
# }

function global:Import-RequiredFunctions {
    param([Parameter( ValueFromPipeline = $true)]
        $gitProfile = $env:gitProfile)

    if (-not $env:localgitProfile) {
        # no profile stored, so load !required functions from github
        $wr = Invoke-WebRequest -Uri "https://api.github.com/repos/$gitProfile/contents/functions/!required"
        $objects = $wr.Content | ConvertFrom-Json
        $files = $objects | where-object { $_.type -eq "file" } | Select-object -exp download_url
                    
        foreach ($file in $files) {
            try {
                Write-Verbose "Loading $file from $env:gitProfile"
                invoke-expression ((New-Object System.Net.WebClient).DownloadString($file)) -ErrorAction Stop
            }
            catch {
                throw "Unable to download '$($file.path)'"
            }
        }
    } 
    else {
        $functionpath = (join-path $here -childpath "functions")
        
        foreach ($file in Get-ChildItem (join-path $functionpath *.ps1) -recurse) {
            . (
                [scriptblock]::Create(
                    [io.file]::ReadAllText($file)
                )
            )
        }
    }
}