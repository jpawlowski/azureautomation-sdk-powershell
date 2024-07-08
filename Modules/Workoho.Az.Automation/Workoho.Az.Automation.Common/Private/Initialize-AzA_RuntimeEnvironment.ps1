function Initialize-AzA_RuntimeEnvironment {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'GlobalVars required to restore ConfirmPreference after module was removed.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Function must run unattended during module import.')]
    param()

    if ($null -eq $IsAzureAutomationJob) {
        $params = @{
            Scope       = 'Script'
            Name        = 'IsAzureAutomationJob'
            Value       = $null -ne $PSPrivateMetadata.JobId
            Option      = 'ReadOnly'
            Description = 'PowerShell is running as an Azure Automation job that can either be in the cloud or on a hybrid worker.'
        }
        Write-Debug "Setting variable 'IsAzureAutomationJob' to $($params.Value)."
        Set-Variable @params
        [void] $Script:ModuleMemberExport.Variable.Add('IsAzureAutomationJob')
    }

    if ($null -eq $IsAzureAutomationSandbox) {
        $params = @{
            Scope       = 'Script'
            Name        = 'IsAzureAutomationSandbox'
            Value       = $IsAzureAutomationJob -and [System.Environment]::MachineName -like 'SANDBOXHOST-*'
            Option      = 'ReadOnly'
            Description = 'PowerShell is running as an Azure Automation job in the cloud.'
        }
        Write-Debug "Setting variable 'IsAzureAutomationSandbox' to $($params.Value)."
        Set-Variable @params
        [void] $Script:ModuleMemberExport.Variable.Add('IsAzureAutomationSandbox')
    }

    if ($null -eq $IsAzureAutomationHybridWorker) {
        $params = @{
            Scope       = 'Script'
            Name        = 'IsAzureAutomationHybridWorker'
            Value       = $IsAzureAutomationJob -and -not $IsAzureAutomationSandbox
            Option      = 'ReadOnly'
            Description = 'PowerShell is running as an Azure Automation job on a hybrid worker.'
        }
        Write-Debug "Setting variable 'IsAzureAutomationHybridWorker' to $($params.Value)."
        Set-Variable @params
        [void] $Script:ModuleMemberExport.Variable.Add('IsAzureAutomationHybridWorker')
    }

    switch -Regex (@([System.Environment]::GetCommandLineArgs())) {
        '(?i)^-NonI(n(t(e(r(a(c(t(i(ve?)?)?)?)?)?)?)?)?)?$' {
            if ($null -eq $IsNonUserInteractive) {
                $params = @{
                    Scope       = 'Script'
                    Name        = 'IsNonUserInteractive'
                    Value       = $true
                    Option      = 'ReadOnly'
                    Description = 'PowerShell was explicitly started in non-interactive user mode'
                }
                Write-Debug "Setting variable 'IsNonUserInteractive' to $($params.Value)."
                Set-Variable @params
                [void] $Script:ModuleMemberExport.Variable.Add('IsNonUserInteractive')
            }
            continue
        }
    }

    if ($null -eq $IsNonUserInteractive) {
        $params = @{
            Scope       = 'Script'
            Name        = 'IsNonUserInteractive'
            Value       = $IsAzureAutomationJob -or $null -eq [System.Environment]::UserInteractive
            Option      = 'ReadOnly'
            Description = 'PowerShell was set into non-interactive user mode'
        }
        Write-Debug "Setting variable 'IsNonUserInteractive' to $($params.Value)."
        Set-Variable @params
        [void] $Script:ModuleMemberExport.Variable.Add('IsNonUserInteractive')
    }

    if ($null -eq $IsUserInteractive) {
        $params = @{
            Scope       = 'Script'
            Name        = 'IsUserInteractive'
            Value       = $IsNonUserInteractive -eq $false
            Option      = 'ReadOnly'
            Description = 'PowerShell is running in user interactive mode'
        }
        Write-Debug "Setting variable 'IsUserInteractive' to $($params.Value)."
        Set-Variable @params
        [void] $Script:ModuleMemberExport.Variable.Add('IsUserInteractive')
    }

    if ($null -eq $PSModuleAutoloadingPreference) {
        $params = @{
            Scope       = 'Script'
            Name        = 'PSModuleAutoloadingPreference'
            Value       = if ($IsAzureAutomationJob) { 'ModuleQualified' } else { 'All' }
            Option      = 'ReadOnly'
            Description = 'In Azure Automation, modules must be explicitly imported using Import-AzA_Module so verbose output can be controlled.'
        }
        Write-Debug "Setting variable 'PSModuleAutoloadingPreference' to $($params.Value)."
        Set-Variable @params
        [void] $Script:ModuleMemberExport.Variable.Add('PSModuleAutoloadingPreference')
    }

    Remove-Variable params -ErrorAction Ignore

    if (
        $IsNonUserInteractive -and
        $null -eq $Global:PreAzAModule_ConfirmPreference
    ) {
        Write-Debug "Setting $ConfirmPreference to 'None' for non-interactive user mode."
        if ($null -ne $Global:ConfirmPreference) {
            $Global:PreAzAModule_ConfirmPreference = $Global:ConfirmPreference
        }
        $Global:ConfirmPreference = 'None' # Set directly to avoid deletion when module is removed so we can restore it.
    }
}
