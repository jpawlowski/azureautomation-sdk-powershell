<#
.SYNOPSIS
    Validates the version of all modules in the Modules directory.
.DESCRIPTION
    This script validates the version of all modules in the Modules directory.
    If the version of any module does not match the specified version, the script will throw an error.
    The version must be in the format 'Major.Minor.Patch[-Prerelease]'.
.PARAMETER Version
    The version to validate against.
.PARAMETER Modules
    An array of module names to validate. If not specified, all modules will be validated.
#>

#Requires -Version 7.2

[CmdletBinding()]
[OutputType([System.String[]])]
param(
    [string[]] $Modules,

    [Parameter(Mandatory = $true)]
    [string] $Version
)

# Flatten $Modules in case any item contains comma-separated values
$Modules = @($Modules | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })

if ($Version -notmatch '^v?\d+(\.\d+)*(-\w+)?$') {
    Write-Error "Invalid version format. Expected format: 'Major.Minor.Patch[-Prerelease]'. Actual version: $Version" -ErrorAction Stop
}
[semver] $Version = $Version.TrimStart('v')

Set-Location -Path (Split-Path -Path $PSScriptRoot -Parent)

try {
    Get-ChildItem -Path "./Modules" -Recurse -Depth 1 -Filter '*.psd1' | ForEach-Object {
        if ($Modules -and ($_.BaseName -notin $Modules)) {
            return
        }
        $file = $_
        $moduleManifest = Import-PowerShellDataFile $file.FullName
        $moduleVersion = $moduleManifest.ModuleVersion
        $prerelease = $moduleManifest.PrivateData.PSData.Prerelease
        $fullVersion = if ($prerelease) { "$moduleVersion-$prerelease" } else { $moduleVersion }
        if ($Version -ne $fullVersion) {
            Write-Error "$($file.Directory.BaseName) version mismatch. Expected version: $Version - Actual version in manifest: $fullVersion" -ErrorAction Stop
        }
    }
}
catch {
    Write-Error "Failed to validate module version. Error: $($_.Exception.Message)"
    exit 1
}
finally {
    Remove-Variable moduleManifest, version, prerelease, fullVersion, destinationPath, archiveFile -ErrorAction Ignore
    Pop-Location
}
