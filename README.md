Sitecore Switch to CD
=============================
The Sitecore-PowerShell-Installer script that switches a Sitecore instance to work as a content delivery one. 
It is used in Octopus as a packaged step, but should be possible to use standalone.


### How To Use
1. Download it
2. Run Powershell as Administrator and invoke ```. .\switch-to-cd.ps1 -deploymentPath C:\inetpub\sc -hostName scinstance.com```

The script runs the Sitecore configuration, and aditionally enables the SwitchMasterToWeb.config.example and removes the connection strings not needed in a CD. 
It erases all files listed in the file \Webroot\Data\FrontToErase.txt
Enables an additional configuration file at \App_Config\Include\zz\Front.config.disabled
Changes the hostname and targetHostname according to the parameters. See example above and help for the command. 


You can see more information on the script's help 
- Get-Help .\switch-to-cd.ps1


### Troubleshooting
- If you see an error in PowerShell complaining that "the execution of scripts is disabled on this system." then you need to invoke ```Set-ExecutionPolicy -ExecutionPolicy unrestricted -Force```
- If you receive a security warning after invoking ```. .\install.ps1``` and want to make it go away permanently, then right-click on the install.ps1 file and "Unblock" it.

This script is using Alessandro Nivuori's configurator scripts https://github.com/alessandronivuori/ServerConfigurator as a submodule