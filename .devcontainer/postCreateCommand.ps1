<#PSScriptInfo
.VERSION 1.0.0
.GUID e06f879d-25ec-4d2c-82b2-2da9af792158
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
    Version 1.0.0 (2024-05-16)
    - Initial release.
#>

<#
.SYNOPSIS
    Run PowerShell commands after the development container has been created.

.DESCRIPTION
    This script is run after the development container has been created.
    For example, it may install additional PowerShell modules.
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Script is run during initialization.')]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

@(
    # 'MyModule'
) | ForEach-Object {
    Write-Host "Installing module $_..."
    Install-Module $_ -Scope AllUsers -AllowClobber -Force -Verbose
}
