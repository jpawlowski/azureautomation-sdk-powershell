@{
    # Script module or binary module file associated with this manifest.
    # RootModule           = ''

    # Version number of this module.
    ModuleVersion        = '2.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @( 'Core' )

    # ID used to uniquely identify this module
    GUID                 = 'cb92c0f0-ec76-4ac4-acd5-af2ebb1c2e33'

    # Author of this module
    Author               = 'Julian Pawlowski'

    # Company or vendor of this module
    CompanyName          = 'Workoho'

    # Copyright statement for this module
    Copyright            = '© Workoho GmbH. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'Helper functions for Azure Automation runbooks.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion    = '7.2'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules      = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    ScriptsToProcess     = @(
        'Initialize-AzA_RuntimeEnvironmentBeforeImport.ps1'
    )

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules        = @(
        '.\Workoho.Az.Automation.Common'
        '.\Workoho.Az.Automation.Azure'
        '.\Workoho.Az.Automation.ExchangeOnline'
        '.\Workoho.Az.Automation.Graph'
    )

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport    = @(

        # Common
        'Convert-AzA_LocalUserIdToUserId'
        'Convert-AzA_PSEnvToPSScriptVariable'
        'Convert-AzA_UserIdToLocalUserId'
        'Get-AzA_RandomPassword'
        'Import-AzA_Module'
        'Submit-AzA_Webhook'
        'Write-AzA_CsvOutput'
        'Write-AzA_Error'
        'Write-AzA_FunctionBegin'
        'Write-AzA_FunctionEnd'
        'Write-AzA_Information'
        'Write-AzA_JsonOutput'
        'Write-AzA_ScriptBegin'
        'Write-AzA_ScriptEnd'
        'Write-AzA_Warning'

        # Azure
        'Confirm-AzA_AzRoleActiveAssignment'
        'Connect-AzA_AzAccount'
        'Get-AzA_AzAutomationJobInfo'
        'Import-AzA_AzAutomationVariableToPSEnv'
        'Invoke-AzA_AzRestMethod'
        'Wait-AzA_AzAutomationConcurrentJob'

        # Exchange Online
        'Connect-AzA_ExchangeOnline'

        # Graph
        'Confirm-AzA_MgAppPermission'
        'Confirm-AzA_MgDirectoryRoleActiveAssignment'
        'Connect-AzA_MgGraph'
        'Find-AzA_MgUserWithSoftDeleted'
        'Get-AzA_MgAppPermission'
        'Get-AzA_MgDirectoryRoleActiveAssignment'
        'Get-AzA_MgUserTypeDetail'
        'Invoke-AzA_MgGraphRequest'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport      = @()

    # Variables to export from this module
    VariablesToExport    = @(

        # PowerShell session
        'ConfirmPreference'
        'IsUserInteractive'
        'IsNonUserInteractive'
        'PSModuleAutoloadingPreference'

        # Azure Automation
        'IsAzureAutomationJob'
        'IsAzureAutomationSandbox'
        'IsAzureAutomationHybridWorker'
    )

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport      = @(

        # Graph
        'Connect-AzA_Graph'
    )

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @(
                'Azure',
                'Automation',
                'AzAutomation'
            )

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/workoho/azureautomation-sdk-powershell/LICENSE.txt'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/workoho/azureautomation-sdk-powershell'

            # A URL to an icon representing this module.
            IconUri      = 'https://github.com/workoho/azureautomation-sdk-powershell/images/icon.png'

            # ReleaseNotes of this module
            ReleaseNotes = @'
            ## 2.0.0
            - Initial release of the Workoho.Az.Automation module.
'@

            # Prerelease string of this module
            Prerelease   = 'preview1'

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
