$versionFile = "version.txt"
$version = ""
if ( Test-Path $versionFile )
{
    $version = Get-Content $versionFile
    if ( $version -eq $null -or $version.Split(".").Count -ne 3) 
    {
        Write-Error "Wrong format for version, use X.Y.Z (semver)"
    }
    
}
else
{
    Write-Error "Version file does not exist"
}

$splitted = $version.Split(".")
$oldVersion = $newVersion = $splitted[0] + "." + $splitted[1] + "." + ([convert]::ToInt32($version.Split(".")[2],10) - 1)

if ( Test-Path .\sitecore-switch-to-cd.$oldVersion.zip )
{
    Remove-Item .\sitecore-switch-to-cd.$oldVersion.zip
}

Compress-Archive -DestinationPath .\sitecore-switch-to-cd.$version.zip -Path .\* -Force 
$newVersion = $splitted[0] + "." + $splitted[1] + "." + ([convert]::ToInt32($version.Split(".")[2],10) + 1)
$newVersion | Out-File -FilePath $versionFile 
