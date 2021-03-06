﻿ <#
.SYNOPSIS
    Set desired CD host for the websites.
.DESCRIPTION
    Sets the desired hostname for the Sitecore site definition websites on a CD env. 
.PARAMETER hostNames
    The hostname keys to replace
.PARAMETER targetHostNames
    The targetHostname keys to replace
.PARAMETER websiteConfigPath
    The fullpath for the file for your solution that contains the site definitions.
.EXAMPLE
    C:\PS> set-websites-hostname.ps1 -hostName @{"local.def"="site.def"; }  -websiteConfigPath C:\inetpub\sitecore.liu\WebRoot\App_Config\Include\Website.config
.NOTES
    Author: Diego Saavedra San Juan
    Date:   Many
#>

param(
    [Parameter(Mandatory=$true)]
    [hashtable]$hostNames, # The hostname hast to translated on the Sitecore website.config configuration file. 
    [Parameter(Mandatory=$false)]
    [hashtable]$targetHostNames, # The targetHostName hast to be translated on the Sitecore website.config configuration file. 
    [Parameter(Mandatory=$true)]
    [string]$websiteConfigPath) # The path to the folder containing the Website.config file you want to change the hostname for
      
Write-Host 'Changing hostnames for sites definitions in ' $websiteConfigPath -ForegroundColor Cyan
if( Test-Path $websiteConfigPath )
{
    [xml]$XmlDocument = Get-Content -Path $websiteConfigPath
    $sites = $XmlDocument.SelectNodes("//site")
    if ( $sites.Count -lt 1 ) 
    {
        Write-Host 'No site elements found on ' $websiteConfigPath ' are you sure this is the right file?' -ForegroundColor Red
        exit 1
    }      
    foreach ( $site in $sites)
    {
        $hostNameAttr = $site.Attributes['hostName']
        if ( $hostNameAttr -ne $null -and $hostNameAttr.'#text'.Length -gt 0  -and $hostNames.ContainsKey($hostNameAttr.'#text'))
        {            
            $finalHostname = $hostNames[$hostNameAttr.'#text'];
            Write-Host "Changing hostName from " $hostNameAttr.'#text' " to " $finalHostName " for site " $site.Attributes['name'] -ForegroundColor Cyan
            $site.SetAttribute('hostName', $finalHostName)            
        }
        $targetHostNameAttr = $site.Attributes['targetHostName']
        if ( $targetHostNameAttr -ne $null -and $targetHostNameAttr.'#text'.Length -gt 0  -and $targetHostNames.ContainsKey($targetHostNameAttr.'#text'))
        {            
            $finalHostname = $targetHostNames[$targetHostNameAttr.'#text'];
            Write-Host "Changing targetHostName from " $targetHostNameAttr.'#text' " to " $finalHostName " for site " $site.Attributes['name'] -ForegroundColor Cyan
            $site.SetAttribute('targetHostName', $finalHostName)            
        }
    }

    Write-Host 'Saving modified sites configurations' -ForegroundColor Cyan
    $XmlDocument.Save($websiteConfigPath)
    Write-Host 'Finished modifiying sites configurations' -ForegroundColor Green
}
else
{
 Write-Host 'Website.config does not exist in ' $websiteConfigPath
}