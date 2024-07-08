<#
.SYNOPSIS
    Compresses all modules in the Modules directory into a zip file.
.DESCRIPTION
    This script compresses all modules in the Modules directory into individual zip files.
    The zip files are saved in the dist directory.
#>

[CmdletBinding()]
param()

Get-ChildItem -Path "$PSScriptRoot/../Modules" -Recurse -Depth 1 -Filter '*.psd1' | ForEach-Object {
    try {
        $moduleManifest = Import-PowerShellDataFile $_.FullName
        $version = $moduleManifest.ModuleVersion
        $prerelease = $moduleManifest.PrivateData.PSData.Prerelease
        $versionDirName = if ($prerelease) { "$version-$prerelease" } else { $version }
        $destinationPath = Join-Path -Path "$PSScriptRoot/../dist" -ChildPath $versionDirName
        $null = New-Item -Path $destinationPath -ItemType Directory -Force -ErrorAction Stop
        $archiveFile = Join-Path -Path $destinationPath -ChildPath "$($_.BaseName).zip"
        Compress-Archive -Path "$($_.Directory.FullName)/*" -DestinationPath $archiveFile -Force -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to compress module $(Join-Path $_.Directory.FullName $_.BaseName). Error: $_"
    }
    finally {
        Remove-Variable moduleManifest, version, prerelease, versionDirName, destinationPath, archiveFile -ErrorAction Ignore
    }
}
