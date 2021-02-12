function global:Set-GitProfile {
    param([Parameter( Mandatory, ValueFromPipeline = $true)]
        [String[]]$gitProfileURL)
        
    if (-not (test-path $profile)) { New-Item -ItemType File -Path $profile -Force | Out-Null } 
    Get-GitProfile $gitProfileURL > $profile
}
function global:Get-GitProfile {
    param([Parameter( ValueFromPipeline = $true)]
        [String[]]$gitProfileURL)
    
    return (New-Object System.Net.WebClient).DownloadString($gitProfileURL)
}
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
function global:Import-RequiredFunctions {
    param([Parameter( ValueFromPipeline = $true)]
        [String[]]$gitProfile)

    # Load all !required functions
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