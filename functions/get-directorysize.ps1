#Functions
function Get-DirectorySize($Path='.',$InType="MB")
{
    $colItems = (Get-ChildItem $Path -recurse | Measure-Object -property length -sum)
    switch ($InType) {
        "GB" { $ret = "{0:N2}" -f ($colItems.sum / 1GB) + " GB" }
        "MB" { $ret = "{0:N2}" -f ($colItems.sum / 1MB) + " MB" }
        "KB" { $ret = "{0:N2}" -f ($colItems.sum / 1KB) + " KB"}
        "B" { $ret = "{0:N2}" -f ($colItems.sum) + " B"}
        Default { $ret = "{0:N2}" -f ($colItems.sum) + " B" }
    }
    Return $ret
}
function Test-IsAdmin {
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}