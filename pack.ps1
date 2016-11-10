$versionFile = "version.txt"
if ( Test-Path $versionFile )
{
    $version = Get-Content $versionFile
}
Compress-Archive -DestinationPath .\sitecore-switch-to-cd.$version.zip -Path .\* -Force
if ( $version -ne $null -and $version.Split(".").Count -eq 3)
{
    $splitted = $version.Split(".")
    $newVersion = $splitted[0] + "." + $splitted[1] + "." + ([convert]::ToInt32($version.Split(".")[2],10) + 1)
    $newVersion | Out-File -FilePath $versionFile 
}