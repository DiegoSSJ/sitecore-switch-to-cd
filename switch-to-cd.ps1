    <#
.SYNOPSIS
    Switches a deployed Sitecore instance to act as a CD instance.
.DESCRIPTION
    Switches a deployed Sitecore instance to act as a CD instance.
    Removes Unicorn configuration
    Does all the changes stated by the Sitecore CD guide.
    https://doc.sitecore.net/sitecore_experience_platform/81/setting_up__maintaining/xdb/configuring_servers/configure_a_content_delivery_server 
.PARAMETER deploymentPath
    The path to the file where the transform is
.PARAMETER deploymentPath
    The hostName for the site definitions
.EXAMPLE
    C:\PS> switch-to-cd1.ps1 -deploymentPath C:\inetpub\sitecore.liu -hostName front.com
.NOTES
    Author: Diego Saavedra San Juan
    Date:   Many
#>


param(
    [Parameter(Mandatory=$true)]
    [string]$deploymentPath,      #The path to deployment. We expect three folder there: Unicorn, Webroot and Deployment. Last one isn't used. 
    [Parameter(Mandatory=$true)]
    [string]$hostName)            #The hostname to switch the site definitions to. 
        


# AS per instructions on https://doc.sitecore.net/sitecore_experience_platform/81/setting_up__maintaining/xdb/configuring_servers/configure_a_content_delivery_server
# Plus Unicorn 

Write-Host 'Switching instance on $deploymentPath: ' $deploymentPath ' to be a CD instance'

# Delete files listed in FrontToErase.txt
Write-Host 'Deleting files and folders specified by FrontToErase.txt'
if ( Test-Path $deploymentPath\Webroot\Data\FrontToErase.txt )
{
    $contents = Get-Content $deploymentPath\Webroot\Data\FrontToErase.txt
    foreach( $line in $contents) 
    {
        if ($line.Length -gt 0 -and $line.Substring(0,1) -ne "#" )
        {
            $toDelete = $deploymentPath + "\" + $line
            Write-Host 'Deleting object ' $toDelete

            if ( Test-Path $toDelete )
            {
                try
                {
                    if ( Test-Path -PathType Container $toDelete)
                    {    
                        Write-Host 'Deleting as folder'
                        Remove-Item -Force -Recurse "$toDelete"  
                    }
                    else 
                    { 
                        Write-Host 'Deleting as file'
                        Remove-Item -Force -LiteralPath "$toDelete"
                    }
                }
                catch { Write-Host 'Error removing' }
            }
            else
            {
                Write-Error 'Object not found, are you sure you wrote the right path in FrontToErase.txt?'
            }
                
        }
    }
}
else
{
    Write-Error 'FrontToErase.txt not found, no files will be deleted'
}

# Enable disable config files as per https://doc.sitecore.net//~/media/2ABDC8F1C30E46B0BACBD9ADF6020197.ashx?la=en
# Using https://github.com/alessandronivuori/ServerConfigurator
Write-Host 'Enabling/disabling configuration files for CD'
ServerConfigurator\install.ps1 $deploymentPath\Webroot ContentDelivery -solr 1 -check 0 -version 8.1rev3 -ignoreWebsitePrefix 1

# Remove unneeded connection strings,  see https://doc.sitecore.net/sitecore_experience_platform/81/setting_up__maintaining/xdb/configuring_servers/database_connection_strings_for_configuring_servers
Write-Host 'Applying connection strings transforms for CD, transforming '
.\apply-xdt-transform.ps1 -sourceXMLTransform .\ConnectionStringsCD.config -targetConfigurationFile $deploymentPath\Webroot\App_Config\ConnectionStrings.config

Write-Host 'Enabling SwitchMasterToWeb.config'
# Rename SwitchMasterToWeb.config.disabled to SwitchMasterToWeb.config
Rename-Item -Path $deploymentPath\Webroot\App_Config\Include\Z.SwitchMasterToWeb\SwitchMasterToWeb.config.example -NewName SwitchMasterToWeb.config

Write-Host 'Enable our own Sitecore patches for fronts'
if ( Test-Path $deploymentPath\Webroot\App_Config\Include\zz\Front.config.disabled )
{
    Rename-Item -Path $deploymentPath\Webroot\App_Config\Include\zz\Front.config.disabled -NewName Front.config
}
else
{
    Write-Error "Front.config.disabled not found, it won't be enabled"
}

# Set sites hostnames
.\set-websites-hostname.ps1 -hostName $hostName -websiteConfigPath $deploymentPath\Webroot\App_Config\Include\Context\Website.config