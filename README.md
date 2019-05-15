# ps-gitprofile
Automagically sync your PowerShell profile across Linux, Windows and Azure Cloud Shell.

To install, just run this code from your PowerShell6 prompt: 

```
iwr aka.ms/psgp | iex
```

You'll have the option of making it your default profile or having it ride shotgun next to your existing profile.

If you choose to have your profile stored in Azure Cloud Shell, you'll need the following information (which will then be stored in PLAINTEXT in $home\.gitprofile -- you've been warned!)
 * Azure Cloud Shell Storage Account Name & Shared Folder Name
 * Azure Cloud Shell Storage Account Key

 When you're bouncing to a new machine and don't want to install the whole profile, you can run the command above and choose 'n' at the first prompt, which will then load only the scripts and functions under the !required folder into the current runspace. Nifty!

 Finally, for advanced users you can clone this repo and change the $env:gitProfile variable at the top of profile.ps1. 