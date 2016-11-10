 <#
.SYNOPSIS
    Set desired CD host for the websites.
.DESCRIPTION
    Sets the desired hostname for the Sitecore site definition websites on a CD env. 
.PARAMETER hostName
    The hostname to set
.PARAMETER websiteConfigPath
    The fullpath for the file for your solution that contains the site definitions.
.EXAMPLE
    C:\PS> set-websites-hostname.ps1 -hostName front.com -websiteConfigPath C:\inetpub\sitecore.liu\WebRoot\App_Config\Include\Website.config
.NOTES
    Author: Diego Saavedra San Juan
    Date:   Many
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$hostName, # The hostname to set on the Sitecore website.config configuration file. 
    [Parameter(Mandatory=$true)]
    [string]$websiteConfigPath) # The path to the folder containing the Website.config file you want to change the hostname for
      
Write-Host 'Changing hostname for sites definitions in ' $websiteConfigPath ' to ' $hostName -ForegroundColor Blue
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
        if ( $hostNameAttr -ne $null -and $hostNameAttr.'#text'.Length -gt 0 )
        {
            $siteName = $site.Attributes['name']
            $finalHostname = $hostname
            if ( $siteName.'#text' -ne "website" )
            {   
                Write-Host "Adding website name " $site.Attributes['name'].'#text' " to hostname "
                $finalHostName = $site.Attributes['name'].'#text' + "." + $hostName
            }
            Write-Host "Changing hostName and targetHostName from " $hostNameAttr.'#text' " to " $finalHostName -ForegroundColor Blue
            $site.SetAttribute('hostName', $finalHostName)
            $site.SetAttribute('targetHostName', $finalHostName)
        }
    }

    Write-Host 'Saving modified sites configurations' -ForegroundColor Blue
    $XmlDocument.Save($websiteConfigPath)
    Write-Host 'Finished modifiying sites configurations' -ForegroundColor Green
}
else
{
 Write-Host 'Website.config does not exist in ' $websiteConfigPath
}