<#
.SYNOPSIS
    Compresses all modules in the Modules directory into a zip file.
.DESCRIPTION
    This script compresses all modules in the Modules directory into individual .zip files.
    The zip files are saved in the dist directory.
.PARAMETER Modules
    An array of module names to compress. If not specified, all modules in the Modules directory will be compressed.
.OUTPUTS
    System.String[]
    An array of full paths to the compressed zip files. There can be multiple paths if there are multiple modules.
#>

#Requires -Version 7.2

[CmdletBinding()]
[OutputType([System.String[]])]
param(
    [string[]] $Modules
)

# Flatten $Modules in case any item contains comma-separated values
$Modules = @($Modules | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })

Set-Location -Path (Split-Path -Path $PSScriptRoot -Parent)

try {
    Get-ChildItem -Path "./Modules" -Recurse -Depth 1 -Filter '*.psd1' | ForEach-Object {
        if ($Modules -and ($_.BaseName -notin $Modules)) {
            return
        }
        $file = $_
        $moduleManifest = Import-PowerShellDataFile $file.FullName
        $version = $moduleManifest.ModuleVersion
        $prerelease = $moduleManifest.PrivateData.PSData.Prerelease
        $fullVersion = if ($prerelease) { "$version-$prerelease" } else { $version }
        $destinationPath = './build_artifacts'
        $null = New-Item -Path $destinationPath -ItemType Directory -Force -ErrorAction Stop
        $archiveFile = Join-Path -Path $destinationPath -ChildPath "$($file.Directory.BaseName).$fullVersion.zip".ToLower()
        Write-Verbose "Compressing module $($file.Directory.BaseName) version $version to $destinationPath into $archiveFile"
        $null = Compress-Archive -Path "$($file.Directory.FullName)/*" -DestinationPath $archiveFile -Force -ErrorAction Stop
        Write-Output (Resolve-Path -Path $archiveFile).Path
    }
}
catch {
    Write-Error "Failed to compress module. Error: $($_.Exception.Message)"
    exit 1
}
finally {
    Remove-Variable moduleManifest, version, prerelease, fullVersion, destinationPath, archiveFile -ErrorAction Ignore
    Pop-Location
}
