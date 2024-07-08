@{
    # Use Severity when you want to limit the generated diagnostic records to a
    # subset of: Error, Warning and Information.
    # Uncomment the following line if you only want Errors and Warnings but
    # not Information diagnostic records.
    Severity = @('Error', 'Warning')

    # Use IncludeRules when you want to run only a subset of the default rule set.
    #IncludeRules = @('PSAvoidDefaultValueSwitchParameter',
    #                 'PSMissingModuleManifestField',
    #                 'PSReservedCmdletChar',
    #                 'PSReservedParams',
    #                 'PSShouldProcess',
    #                 'PSUseApprovedVerbs',
    #                 'PSUseDeclaredVarsMoreThanAssigments')

    # Use ExcludeRules when you want to run most of the default set of rules except
    # for a few rules you wish to "exclude".  Note: if a rule is in both IncludeRules
    # and ExcludeRules, the rule will be excluded.
    ExcludeRules   = @(
        'PSMissingModuleManifestField'
    )

    # CustomRulePath = @(
    #     # Path to the custom rule module
    #     #'.github/linters/.powershell-psscriptanalyzer.psm1'
    # )

    # You can use the following entry to supply parameters to rules that take parameters.
    # For instance, the PSAvoidUsingCmdletAliases rule takes a whitelist for aliases you
    # want to allow.
    Rules    = @{
        PSAvoidUsingCmdletAliases = @{
            Enable    = $true
            Whitelist = @( 'cd' )
        }

        PSUseCompatibleCmdlets    = @{
            Enable        = $true
            compatibility = @(
                'core-6.1.0-windows'
                'core-6.1.0-linux'
                'core-6.1.0-linux-arm'
                'core-6.1.0-macos'
            )
        }

        PSUseCompatibleCommands   = @{
            Enable         = $true
            TargetProfiles = @(
                'win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core'
                'ubuntu_x64_18.04_7.0.0_x64_3.1.2_core'
            )
            IgnoreCommands = @(
                'Install-Module'
                'Install-PSResource'
            )
        }

        PSUseCompatibleSyntax     = @{
            Enable         = $true
            TargetVersions = @(
                '7.2'
            )
        }

        PSUseCompatibleTypes      = @{
            Enable         = $true
            TargetProfiles = @(
                'win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core'
                'ubuntu_x64_18.04_7.0.0_x64_3.1.2_core'
            )
            IgnoreTypes    = @(
                'System.IO.Compression.ZipFile'
            )
        }
    }
}
