<#
.SYNOPSIS
    Download all modules in the Modules directory from the PowerShell Gallery.
.DESCRIPTION
    This script downloads all modules in the Modules directory from the PowerShell Gallery into individual .nupkg files.
    The .nupkg files are saved in the dist directory.
.PARAMETER Modules
    An array of module names to download. If not specified, all modules in the Modules directory will be downloaded.
.OUTPUTS
    System.String[]
    An array of full paths to the downloaded .nupkg files. There can be multiple paths if there are multiple modules.
#>

#Requires -Version 7.2

[CmdletBinding()]
[OutputType([System.String[]])]
param(
    [string[]] $Modules,
    [string] $Repository = 'PSGallery'
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
        $archiveFile = Join-Path -Path (Resolve-Path -Path $destinationPath) -ChildPath "$($file.Directory.BaseName).$fullVersion.nupkg".ToLower()
        $Uri = (Get-PSRepository -Name $Repository -ErrorAction Stop).PublishLocation.TrimEnd('/') + "/$($file.Directory.BaseName)/$fullVersion"
        Write-Verbose "Downloading module $($file.Directory.BaseName) version $version to $destinationPath from $Uri"
        $attempt = 0
        while ($true) {
            try {
                Invoke-WebRequest -Uri $Uri -OutFile $archiveFile -ErrorAction Stop
                Write-Output $archiveFile
                break
            }
            catch {
                if ($_.Exception.Message -match '404') {
                    Write-Warning "Module $($file.Directory.BaseName) version $fullVersion not found on the PowerShell Gallery. Skipping."
                    break
                }
                Write-Warning "Failed to download module $($file.Directory.BaseName) version $fullVersion. Error: $($_.Exception.Message)"
                $attempt++
                if ($attempt -ge 3) {
                    Write-Error "Failed to download module $($file.Directory.BaseName) version $fullVersion after $attempt attempts. Exiting."
                    exit 1
                }
                Start-Sleep -Seconds 5
            }
        }
    }
}
catch {
    Write-Error "Failed to download module. Error: $($_.Exception.Message)"
    exit 1
}
finally {
    Remove-Variable moduleManifest, version, prerelease, fullVersion, destinationPath, archiveFile, Uri, attempt -ErrorAction Ignore
    Pop-Location
}
