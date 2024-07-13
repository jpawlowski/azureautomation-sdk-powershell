#
# Module manifest for module 'Workoho.Automation'
#
# Generated by: Julian Pawlowski
#
# Generated on: 7/13/2024
#

@{

# Script module or binary module file associated with this manifest.
# RootModule = ''

# Version number of this module.
ModuleVersion = '2.0.0'

# Supported PSEditions
CompatiblePSEditions = 'Core'

# ID used to uniquely identify this module
GUID = 'cb92c0f0-ec76-4ac4-acd5-af2ebb1c2e33'

# Author of this module
Author = 'Julian Pawlowski'

# Company or vendor of this module
CompanyName = 'Workoho'

# Copyright statement for this module
Copyright = '© Workoho GmbH. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Helper functions for Azure Automation runbooks.'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '7.2'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
ScriptsToProcess = 'Initialize-Auto_RuntimeEnvironmentBeforeImport.ps1'

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @('.\Workoho.Automation.Common',
               '.\Workoho.Automation.Azure',
               '.\Workoho.Automation.ExchangeOnline',
               '.\Workoho.Automation.Graph')

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Convert-Auto_LocalUserIdToUserId',
               'Convert-Auto_PSEnvToPSScriptVariable',
               'Convert-Auto_UserIdToLocalUserId', 'Get-Auto_RandomPassword',
               'Import-Auto_Module', 'Submit-Auto_Webhook', 'Write-Auto_CsvOutput',
               'Write-Auto_Error', 'Write-Auto_FunctionBegin',
               'Write-Auto_FunctionEnd', 'Write-Auto_Information',
               'Write-Auto_JsonOutput', 'Write-Auto_ScriptBegin',
               'Write-Auto_ScriptEnd', 'Write-Auto_Warning',
               'Confirm-Auto_AzRoleActiveAssignment', 'Connect-Auto_AzAccount',
               'Get-Auto_AzAutomationJobInfo',
               'Import-Auto_AzAutomationVariableToPSEnv',
               'Invoke-Auto_AzRestMethod', 'Wait-Auto_AzAutomationConcurrentJob',
               'Connect-Auto_ExchangeOnline', 'Confirm-Auto_MgAppPermission',
               'Confirm-Auto_MgDirectoryRoleActiveAssignment',
               'Connect-Auto_MgGraph', 'Find-Auto_MgUserWithSoftDeleted',
               'Get-Auto_MgAppPermission',
               'Get-Auto_MgDirectoryRoleActiveAssignment',
               'Get-Auto_MgUserTypeDetail', 'Invoke-Auto_MgGraphRequest'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = 'ConfirmPreference', 'IsContainerized', 'IsUserInteractive',
               'IsNonUserInteractive', 'PSModuleAutoloadingPreference',
               'IsAzureAutomationJob', 'IsAzureAutomationSandbox',
               'IsAzureAutomationHybridWorker'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = 'Connect-Auto_Graph'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'Azure', 'Automation', 'AzAutomation', 'PowerShell'

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/workoho/automation-sdk-powershell/LICENSE.txt'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/workoho/automation-sdk-powershell'

        # A URL to an icon representing this module.
        IconUri = 'https://github.com/workoho/automation-sdk-powershell/images/icon.png'

        # ReleaseNotes of this module
        ReleaseNotes = 'For detailed release notes, please visit https://github.com/workoho/automation-sdk-powershell/releases'

        # Prerelease string of this module
        Prerelease = 'alpha1'

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable


} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

