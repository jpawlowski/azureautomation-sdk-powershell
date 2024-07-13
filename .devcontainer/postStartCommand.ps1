<#PSScriptInfo
.VERSION 1.0.0
.GUID d92048e2-8a2c-4954-81dd-80bf829e1e24
.AUTHOR Julian Pawlowski
.COMPANYNAME Workoho GmbH
.COPYRIGHT © 2024 Workoho GmbH
.TAGS
.LICENSEURI https://github.com/workoho/automation-sdk-powershell/blob/main/LICENSE.txt
.PROJECTURI https://github.com/workoho/automation-sdk-powershell
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
    Version 1.0.0 (2024-07-08)
    - Initial release.
#>

<#
.SYNOPSIS
    Run PowerShell commands after the development container has been started.

.DESCRIPTION
    This script is run after the development container has been started.
    For example, it may alter your local profile.
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Script is run during initialization.')]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$profilePath = $PROFILE.CurrentUserAllHosts
$profileDir = Split-Path -Path $profilePath -Parent
if (-not (Test-Path -Path $profileDir)) {
    Write-Host "Creating profile directory $profileDir"
    $null = New-Item -ItemType Directory -Path $profileDir -Force
}

$psModulePathUpdateCommand = "`$env:PSModulePath = `"$((Get-ChildItem -Path '/workspaces/*.psm1', '/workspaces/*.psd1' -Recurse -File | Select-Object -Property Directory -Unique).Directory.Parent.FullName -join ':'):`$env:PSModulePath`""
Write-Host "Updating PSModulePath in $profilePath"
Set-Content -Path $profilePath -Value $psModulePathUpdateCommand -Force
