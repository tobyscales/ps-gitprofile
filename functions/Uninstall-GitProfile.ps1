function uninstall-GitProfile {
    if ($env:LocalGitProfile) { $here = split-path($env:LocalGitProfile) } else { $here = split-path($profile) }
    
write-host "Removing from $here"
set-location $home

Remove-Item -Path "$here" -Recurse -force
Remove-Item -Path "$home\.gitprofile" -Recurse -force
Remove-Item -Path $env:LocalGitProfile -force
}