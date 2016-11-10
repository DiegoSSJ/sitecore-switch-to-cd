    <#
.SYNOPSIS
    Applies XML XDT transform to a file. 
.DESCRIPTION
    Applies XML XDT transform to a file. 
    From http://stackoverflow.com/questions/8989737/web-config-transforms-outside-of-microsoft-msbuild#16798553
.PARAMETER sourceXMLTransform 
    The path to file where the transform is
.PARAMETER targetConfigurationFile
    The file to apply the transform to
.EXAMPLE
    C:\PS> apply-xdt-transform.ps1 -sourceXMLTransform source.config -targetConfigurationFile target.config    
.NOTES
    Author: Diego Saavedra San Juan
    Date:   Many
#>



param(
    [Parameter(Mandatory=$true)]
    [string]$sourceXMLTransform, #The path to file where the transform is
    [Parameter(Mandatory=$true)]
    [string]$targetConfigurationFile=$false)   #Set the solr service to be started for use with solrCloud    
        
            
$xdt=$sourceXMLTransform
$xml=$targetConfigurationFile
    
if (!$xml -or !(Test-Path -path $xml -PathType Leaf)) {
    throw "File not found. $xml";
}
if (!$xdt -or !(Test-Path -path $xdt -PathType Leaf)) {
    throw "File not found. $xdt";
}

#$scriptPath = (Get-Variable MyInvocation -Scope 1).Value.InvocationName | split-path -parent
Add-Type -LiteralPath ".\Microsoft.Web.XmlTransform.dll"

$xmldoc = New-Object Microsoft.Web.XmlTransform.XmlTransformableDocument;
$xmldoc.PreserveWhitespace = $true
$xmldoc.Load($xml);

$transf = New-Object Microsoft.Web.XmlTransform.XmlTransformation($xdt);
if ($transf.Apply($xmldoc) -eq $false)
{
    throw "Transformation failed."
}
$xmldoc.Save($xml);