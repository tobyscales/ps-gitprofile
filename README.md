# ps-gitprofile
Automagically sync your PowerShell profile across Linux, Windows and Azure Cloud Shell.

To run at your current PowerShell6 prompt, simply type: 

```
iwr aka.ms/psgp | iex
```

This will give you the [default profile](https://github.com/tescales/ps-gitprofile/blob/master/Git.PowerShell_profile.ps1) and pre-load the functions in the [!required](https://github.com/tescales/ps-gitprofile/tree/master/functions/!required) folder.

You can load additional functions by running `. Import-GitFunction Function-Name`. (Note you need to dot-source the Import-GitFunction command to make the function available in your current session!)

This mode is referred to as "non-persistent" mode since all the loaded functions and settings automatically disappear when you close your session. It's also a great way to try out the profile and see if you like it!

To make ps-gitprofile your default profile, run the above command then 
```
Initialize-GitProfile 
```

This will also give you the option to automount your Azure Cloud Shell drive on every execution. In order to do that, you'll need the following information (which will then be stored in PLAINTEXT in your PowerShell $profile -- you've been warned!)
 * Azure Cloud Shell Storage Account Name & Shared Folder Name
 * Azure Cloud Shell Storage Account Key

Finally, for advanced users you can clone this repo and change the $env:gitProfile variable at the top of profile.ps1 to point all the defaults to your repository instead. 

#TODO:
* ~~Cleanup logic in Import-GitFunction to allow case mismatches~~
* ~~Add "isAdmin" check for Mac/Linux root~~
* Add case-insensitivity to Get-GitFiles
* Add ability to update profile.ps1 after initial setup (version check for updater script)
* Refactor with Environment:: instead of $env: per https://powershell.org/2019/02/tips-for-writing-cross-platform-powershell-code/
* Add git support for 2-way sync
* Add MacOS support for Cloudshell
* Add auto-detection of Cloudshell environment
* TO ADD: auto-import ARM snippets: https://danielpaulus.com/arm-templates-with-visual-studio-code/
* TO ADD: auto-debug ARM tempaltes: https://azure.microsoft.com/en-us/blog/debugging-arm-template-deployments/
* TO ADD: CSS-styling for GH Markdown: https://gist.github.com/JamesMessinger/5d31c053d0b1d52389eb2723f7550907
* ~~add scriptblock logic for import-gitfunction to allow direct import (without dot-sourcing)~~ (doesn't seem this is possible)
