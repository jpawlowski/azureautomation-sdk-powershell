function Initialize-Auto_RuntimeEnvironment {
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

    if ($null -eq $IsContainerized) {
        $params = @{
            Scope       = 'Script'
            Name        = 'IsContainerized'
            Value       = (
                $IsAzureAutomationSandbox -or # Azure Automation sandbox hosts are containerized
                $IsAzureAutomationHybridWorker -or # Azure Automation hybrid workers are containerized
                $env:POWERSHELL_DISTRIBUTION_CHANNEL -like 'PSDocker*' -or # Official PowerShell images set this environment variable
                $env:DOTNET_RUNNING_IN_CONTAINER -or # .NET 6.0+ sets this environment variable
                $env:DOTNET_RUNNING_IN_CONTAINERS -or # .NET 6.0+ sets this environment variable
                $env:REMOTE_CONTAINERS -or # Visual Studio Code Remote Containers sets this environment variable
                $env:GITHUB_CODESPACES -or # GitHub Codespaces sets this environment variable
                $env:AWS_CLOUD9_USER -or # AWS Cloud9 sets this environment variable
                $env:DOCKER_CONTAINER -or # Some Docker images set this environment variable
                $env:KUBERNETES_SERVICE_HOST -or # Kubernetes sets this environment variable
                $env:CONTAINER -or # Some container runtimes set this environment variable
                $env:container -or # Some container runtimes set this environment variable
                ($PID -eq 1) -or # Check if the process is running as PID 1
                (Test-Path '/.dockerenv') -or # Docker containers often have this file
                (Test-Path '/.dockerinit') -or # Docker containers often have this file (older versions)
                (
                    (Test-Path '/proc/1/cgroup') -and
                    (
                        (Get-Content '/proc/1/cgroup' | Select-String 'docker') -or # Check if the process is running inside Docker
                        (Get-Content '/proc/1/cgroup' | Select-String '/lxc/') # Check if the process is running inside LXC
                    )
                )
            )
            Option      = 'ReadOnly'
            Description = 'PowerShell is running in a container environment.'
        }
        Write-Debug "Setting variable 'IsContainerized' to $($params.Value)."
        Set-Variable @params
        [void] $Script:ModuleMemberExport.Variable.Add('IsContainerized')
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
            Description = 'In Azure Automation, modules must be explicitly imported using Import-Auto_Module so verbose output can be controlled.'
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
