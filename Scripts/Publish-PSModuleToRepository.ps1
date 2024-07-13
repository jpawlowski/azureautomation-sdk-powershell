<#
.SYNOPSIS
    Publish all modules in the Modules directory to the PowerShell Gallery.
.DESCRIPTION
    This script publishes all modules in the Modules directory to the PowerShell Gallery.
.PARAMETER Modules
    An array of module names to publish. If not specified, all modules in the Modules directory will be published.
.PARAMETER Repository
    The name of the PowerShell repository to publish the modules to. Default is 'PSGallery'.
.PARAMETER ApiKey
    The API key for the PowerShell repository. If not provided, the PSResourceRepositoryApiKey environment variable must be set.
.OUTPUTS
    System.String[]
    An array of successfully published module names. There can be multiple names if there are multiple modules.
#>

#Requires -Version 7.2
#Requires -Modules @{ ModuleName='Microsoft.PowerShell.PSResourceGet'; ModuleVersion='1.0.5' }

[CmdletBinding()]
[OutputType([System.String[]])]
param(
    [string[]] $Modules,
    [string] $Repository = 'PSGallery',
    [object] $ApiKey
)

if (-not $ApiKey) {
    if ($env:PSResourceRepositoryApiKey) {
        $ApiKey = $env:PSResourceRepositoryApiKey
    }
    else {
        Write-Error 'Either the ApiKey parameter or the PSResourceRepositoryApiKey environment variable must be provided.'
        exit 1
    }
}

if (
    $ApiKey -isnot [string] -and
    $ApiKey -isnot [securestring]
) {
    Write-Error 'ApiKey must be a string or a SecureString.'
    exit 1
}

# Flatten $Modules in case any item contains comma-separated values
$Modules = @($Modules | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })

Set-Location -Path (Split-Path -Path $PSScriptRoot -Parent)

try {
    Get-ChildItem -Path "./Modules" -Recurse -Depth 1 -Filter '*.psd1' | ForEach-Object {
        if ($Modules -and ($_.BaseName -notin $Modules)) {
            return
        }
        $file = $_

        if ($file.Directory.BaseName -ne $file.BaseName) {
            Write-Error "Module manifest file name '$($file.BaseName)' must match the module directory name '$($file.Directory.BaseName)'. Skipping."
            return
        }

        $moduleManifest = Import-PowerShellDataFile $file.FullName
        $version = $moduleManifest.ModuleVersion
        $prerelease = $moduleManifest.PrivateData.PSData.Prerelease
        $fullVersion = if ($prerelease) { "$version-$prerelease" } else { $version }
        Write-Verbose "Publishing module $($file.Directory.FullName) version $fullVersion to the PowerShell Gallery"
        $attempt = 0
        while ($true) {
            try {
                Publish-PSResource -Repository $Repository -Path $file.Directory.FullName -ApiKey $( if ($ApiKey -is [securestring]) { ConvertFrom-SecureString -AsPlainText } else { $ApiKey }) -ErrorAction Stop
                Write-Output $($file.Directory.BaseName)
                break
            }
            catch {
                if ($_.Exception.Message -match '403') {
                    Throw $_
                }
                if ($_.Exception.Message -match '409') {
                    Write-Warning "Module $($file.Directory.BaseName) version $fullVersion already exists on the PowerShell Gallery. Skipping."
                    break
                }
                Write-Warning "Failed to publish module $($file.Directory.BaseName) version $fullVersion. Error: $($_.Exception.Message)"
                $attempt++
                if ($attempt -ge 3) {
                    Write-Error "Failed to publish module $($file.Directory.BaseName) version $fullVersion after $attempt attempts. Exiting."
                    exit 1
                }
                Start-Sleep -Seconds 5
            }
        }
    }
}
catch {
    Write-Error "Failed to publish module $($file.Directory.BaseName). Error: $($_.Exception.Message)"
    exit 1
}
finally {
    Remove-Variable moduleManifest, version, prerelease, fullVersion, attempt -ErrorAction Ignore
    Pop-Location
}
