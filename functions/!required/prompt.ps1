# prompt customization coming from the following:
# http://winterdom.com/2008/08/mypowershellprompt
# http://www.wahidsaleemi.com/2018/12/sharing-my-powershell-profile/
# https://about-azure.com/2018/02/16/configure-azure-cloud-shell-to-use-a-profile-hosted-on-github/

function Get-Time { return $(get-date | ForEach-Object { $_.ToLongTimeString() } ) }

# This is function is called by convention in PowerShell
function global:prompt { 
    #Put the full path in the title bar
    $host.UI.RawUI.WindowTitle = Get-Location + " " + Get-Time
   
    # our theme 
    $cdelim = [ConsoleColor]::DarkCyan 
    $chost = [ConsoleColor]::Green 
    $cloc = [ConsoleColor]::Cyan 

    #Set text color based on admin
    if ($isAdmin) {
        $chost = [ConsoleColor]::Red
    }

    write-host "$([char]0x0A7) " -n -f $cloc 
    write-host ([net.dns]::GetHostName()) -n -f $chost 
    write-host ' {' -n -f $cdelim 
    $shortPath = (($pwd.path).Replace($HOME, '~')).replace('\\(\.?)([^\\])[^\\]*(?=\\)', '\$1$2') 
    $shortPath = $shortPath -replace '^[^:]+::', '' 
    write-host $shortPath -n -f $cloc 
    write-host '}' -n -f $cdelim 
    write-host $(if ($nestedpromptlevel -ge 1) { '>>' }) -noNewLine
    
    #   $global:GitStatus = Get-GitStatus
    #   Write-GitStatus $GitStatus

    return '> '
}

#Enable-GitColors
