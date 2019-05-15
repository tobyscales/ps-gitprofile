# prompt customization coming from the following:
# http://winterdom.com/2008/08/mypowershellprompt
# http://www.wahidsaleemi.com/2018/12/sharing-my-powershell-profile/
# https://about-azure.com/2018/02/16/configure-azure-cloud-shell-to-use-a-profile-hosted-on-github/

function Get-Time { return $(get-date | foreach { $_.ToLongTimeString() } ) }

# This is function is called by convention in PowerShell
 function global:prompt { 
   $console = $host.ui.RawUI
   
   # our theme 
   $cdelim = [ConsoleColor]::DarkCyan 
   $chost = [ConsoleColor]::Green 
   $cloc = [ConsoleColor]::Cyan 

   write-host "$([char]0x0A7) " -n -f $cloc 
   write-host ([net.dns]::GetHostName()) -n -f $chost 
   write-host ' {' -n -f $cdelim 
   $shortPath = (($pwd.path).Replace($HOME, '~')).replace('\\(\.?)([^\\])[^\\]*(?=\\)','\$1$2') 
   $shortPath = $shortPath -replace '^[^:]+::', '' 
   write-host $shortPath -n -f $cloc 
   write-host '}' -n -f $cdelim 

   #Set text color based on admin
   if ($isAdmin) {
      $console.ForegroundColor = 'Red'
    }
    
#   $global:GitStatus = Get-GitStatus
#   Write-GitStatus $GitStatus

   return '> '
}


#function global:prompt {
#    #Put the full path in the title bar
#    $console = $host.ui.RawUI
#    $console.ForegroundColor = "gray"
#    $host.UI.RawUI.WindowTitle = Get-Location
 
    #Set text color based on admin
#    if ($isAdmin) {
#        $userColor = 'Red'
#    }
#    else {
#        $userColor = 'White'
#    }
    # Write the time 
#    write-host "[" -noNewLine
#    write-host $(Get-Time) -foreground yellow -noNewLine
#    write-host "] " -noNewLine
    # Write the path
#    write-host $($(Get-Location).Path.replace($home,"~").replace("\","/")) -foreground green -noNewLine
#    write-host $(if ($nestedpromptlevel -ge 1) { '>>' }) -noNewLine
#    return "> "
#}
#Enable-GitColors
