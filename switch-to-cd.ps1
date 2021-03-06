﻿    <#
.SYNOPSIS
    Switches a deployed Sitecore instance to act as a CD instance.
.DESCRIPTION
    Switches a deployed Sitecore instance to act as a CD instance.
    Removes Unicorn configuration
    Does all the changes stated by the Sitecore CD guide.
    https://doc.sitecore.net/sitecore_experience_platform/81/setting_up__maintaining/xdb/configuring_servers/configure_a_content_delivery_server 
.PARAMETER deploymentPath
    The path to where the Sitecore instance was deployed. This is the path up the Website or similar
.PARAMETER hostNames
    The hostNames to replace for the site definitions. This is a key pair array in the form @{"localhostname"="site.com"; "othersitelocal"="othersite.com"}.
    Set it empty is you want to skip altering hostname attribute for site definitions in CD instances of Sitecore. 
    The site definitions should be in \App_Config\Include\Context\Website.config
.PARAMETER targetHostNames
    Same as hostNames but for targetHostNames. 
.PARAMETER webroot
    The additional and optional name for the webroot for the instance. Default is Website
.EXAMPLE
    C:\PS> switch-to-cd1.ps1 -deploymentPath C:\inetpub\sitecore.liu -hostName front.com -webroot "Webroot"
.NOTES
    Author: Diego Saavedra San Juan
    Date:   Many
#>


param(
    [Parameter(Mandatory=$true)]
    [string]$deploymentPath,      # The path to deployment. We expect three folders there: Unicorn, Webroot and Deployment. Last one isn't used. 
    [Parameter(Mandatory=$true)]
    [hashtable]$hostNames,            # The hostnames to switch the site definitions to. See help for format and more information.
    [Parameter(Mandatory=$true)]
    [hashtable]$targetHostNames,      # Same as hostNames but for the targetHostName attributes of site definitions
    [Parameter(Mandatory=$false)]
    [string]$webroot="Website",        # The path to the Website
    [Parameter(Mandatory=$false)]
    [string]$collectionDatabaseHostname)   # the Hostname to the collection database mongodb instance
        


# AS per instructions on https://doc.sitecore.net/sitecore_experience_platform/81/setting_up__maintaining/xdb/configuring_servers/configure_a_content_delivery_server
# Plus Unicorn 

Write-Host 'Switching instance on $deploymentPath: ' $deploymentPath ' to be a CD instance'


# Try to get Sitecore version from instance
$sitecoreVersionFilePath="$deploymentPath\$webroot\sitecore\shell\sitecore.version.xml"
$sitecoreVersionString = ""
if ( Test-Path $sitecoreVersionFilePath )
{
    try {
        [xml]$sitecoreVersionXml = Get-Content -Path $deploymentPath\$webroot\sitecore\shell\sitecore.version.xml
        $sitecoreVersionString = $sitecoreVersionXml.information.version.major + "." + $sitecoreVersionXml.information.version.minor + "-rev-" + $sitecoreVersionXml.information.version.revision
    }
    catch
    {
        Write-Error "Trying to get sitecore version string: " $_.Exception
        exit 1
    }
}
else
{
    Write-Error "Couldn't get Sitecore version from instance. Couldn't find sitecore.version.xml at $sitecoreVersionFilePath"
    exit 1
}
Write-Verbose "Sitecore version found: $sitecoreVersionString"


# Delete files listed in FrontToErase.txt
# Todo: move to own script
Write-Host "Deleting files and folders specified by "$deploymentPath"\"$webroot"\Data\FrontToErase.txt"
if ( Test-Path $deploymentPath"\"$webroot\Data\FrontToErase.txt )
{
    $contents = Get-Content $deploymentPath"\"$webroot\Data\FrontToErase.txt
    foreach( $line in $contents) 
    {
        if ($line.Length -gt 0 -and $line.Substring(0,1) -ne "#" )
        {
            $toDelete = $deploymentPath+"\"+$line
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
                catch { Write-Host 'ERROR: removing:' $_.Exception.Message }
            }
            else
            {
                Write-Host 'ERROR: Object not found, are you sure you wrote the right path in FrontToErase.txt?'
            }
                
        }
    }
}
else
{
    Write-Host 'ERROR: FrontToErase.txt not found, no files will be deleted'
}

# Enable disable config files as per https://doc.sitecore.net//~/media/2ABDC8F1C30E46B0BACBD9ADF6020197.ashx?la=en
# Using https://github.com/alessandronivuori/ServerConfigurator
Write-Host 'Enabling/disabling configuration files for CD'
ServerConfigurator\install.ps1 $deploymentPath"\"$webroot ContentDelivery -searchProviderUsed "solr" -check 0 -version $sitecoreVersionString -ignoreWebsitePrefix 1

# Remove unneeded connection strings,  see https://doc.sitecore.net/sitecore_experience_platform/81/setting_up__maintaining/xdb/configuring_servers/database_connection_strings_for_configuring_servers
Write-Host 'Applying connection strings transforms for CD, transforming '
.\apply-xdt-transform.ps1 -sourceXMLTransform .\ConnectionStringsCD.config -targetConfigurationFile $deploymentPath"\"$webroot\App_Config\ConnectionStrings.config

if ( $sitecoreVersionString.Contains("8.1") )
{
    Write-Host 'Enabling SwitchMasterToWeb.config'
    # Rename SwitchMasterToWeb.config.disabled to SwitchMasterToWeb.config
    Rename-Item -Path $deploymentPath"\"$webroot\App_Config\Include\Z.SwitchMasterToWeb\SwitchMasterToWeb.config.example -NewName SwitchMasterToWeb.config
}

# Set sites hostnames
.\set-websites-hostname.ps1 -hostNames $hostNames -targetHostNames $targetHostNames -websiteConfigPath $deploymentPath"\"$webroot\App_Config\Include\Context\Website.config

# Activate .cdonly config files
Write-Host 'Enabling all .config.cdonly files'
Get-ChildItem -Path $deploymentpath"\"$webroot\App_Config -Filter "*.config.cdonly" -Recurse -File  | % { ren $_.FullName $_.FullName.TrimEnd(".cdonly") -Verbose }

# Configure xDB
if ( $collectionDatabaseHostname -ne $null -and $collectionDatabaseHostname -ne "")
{
    Write-Host 'Setting collection database connection strings hostname'
    if ( -not (Test-Path $deploymentpath"\"$webroot\App_Config\ConnectionStrings.config))
    {
        Write-Error "Connection strings file not found at $deploymentpath"\"$webroot\App_Config\ConnectionStrings.config"
    }
    if (((Get-Content $deploymentpath"\"$webroot\App_Config\ConnectionStrings.config) -match "mongodb").Length -eq 0)
    {
        Write-Warning "No mongodb connection string found, nothing will be replaced"
    }

    Write-Host "Found connection strings file and collection database entries, replacing mongodb hostname entries with $collectionDatabaseHostname"
    (Get-Content $deploymentpath"\"$webroot\App_Config\ConnectionStrings.config) -replace 'mongodb://[^/;]*/',("mongodb://"+$collectionDatabaseHostname+"/") | Out-File -Encoding ascii $deploymentpath"\"$webroot\App_Config\ConnectionStrings.config
    Write-Host "Done setting up collection database new hostname"
}