<#
.SYNOPSIS
    Connects to Azure using either a Managed Service Identity or an interactive session.

.DESCRIPTION
    This runbook connects to Azure using either a Managed Service Identity or an interactive session, depending on the execution environment.

    The script also retrieves the following information about the current Azure Automation Account and sets them as environment variables:
    - AZURE_AUTOMATION_AccountId
    - AZURE_AUTOMATION_SubscriptionId
    - AZURE_AUTOMATION_ResourceGroupName
    - AZURE_AUTOMATION_AccountName
    - AZURE_AUTOMATION_IDENTITY_PrincipalId
    - AZURE_AUTOMATION_IDENTITY_TenantId
    - AZURE_AUTOMATION_IDENTITY_Type
    - AZURE_AUTOMATION_RUNBOOK_Name
    - AZURE_AUTOMATION_RUNBOOK_CreationTime
    - AZURE_AUTOMATION_RUNBOOK_LastModifiedTime
    - AZURE_AUTOMATION_RUNBOOK_JOB_CreationTime
    - AZURE_AUTOMATION_RUNBOOK_JOB_StartTime

    This information can be used by other runbooks afterwards to retrieve details about the current runbook and job.
    Please note that this information involves connecting to Microsoft Graph.
    However, due to incompatible modules, it is important that this script connects to Azure first before a connection to Microsoft Graph is established.
    Only then the environment variables can be set correctly. This is why the environment variables are set in a separate step using the parameter SetEnvVarsAfterMgConnect.

.PARAMETER Tenant
    Specifies the Azure AD tenant ID to use for authentication. If not provided, the default tenant will be used.

.PARAMETER Subscription
    Specifies the Azure subscription ID to use. If not provided, the default subscription will be used.

.PARAMETER SetEnvVarsAfterMgConnect
    Specifies whether to set environment variables after connecting to Microsoft Graph. Default is $false.

.EXAMPLE
    PS> Connect-AzA_AzAccount -Tenant 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -Subscription 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
    Connects to Azure using the specified tenant and subscription.

.EXAMPLE
    PS> Connect-AzA_AzAccount
    Connects to Azure using the default tenant and subscription.
#>

function Connect-AzA_AzAccount {
    [CmdletBinding()]
    Param(
        [string]$Tenant,
        [string]$Subscription,
        [bool]$SetEnvVarsAfterMgConnect
    )

    Write-AzA_FunctionBegin $MyInvocation -OnceOnly

    #region [COMMON] ENVIRONMENT ---------------------------------------------------
    Import-AzA_Module @(
        @{ Name = 'Az.Accounts'; MinimumVersion = '3.0.0' }
    )
    #endregion ---------------------------------------------------------------------

    #region [COMMON] FUNCTIONS -----------------------------------------------------
    function Initialize-EnvVarsAfterMgConnect {
        param()

        if ($IsAzureAutomationJob) {
            if (
                $env:AZURE_AUTOMATION_SubscriptionId -and
                $env:AZURE_AUTOMATION_ResourceGroupName -and
                $env:AZURE_AUTOMATION_AccountName -and
                $env:AZURE_AUTOMATION_IDENTITY_PrincipalId -and
                $env:AZURE_AUTOMATION_IDENTITY_TenantId -and
                $env:AZURE_AUTOMATION_IDENTITY_Type -and
                $env:AZURE_AUTOMATION_RUNBOOK_Name -and
                $env:AZURE_AUTOMATION_RUNBOOK_CreationTime -and
                $env:AZURE_AUTOMATION_RUNBOOK_LastModifiedTime -and
                $env:AZURE_AUTOMATION_RUNBOOK_JOB_CreationTime -and
                $env:AZURE_AUTOMATION_RUNBOOK_JOB_StartTime -and
                $env:AZURE_AUTOMATION_RUNBOOK_CreationTime -and
                $env:AZURE_AUTOMATION_RUNBOOK_LastModifiedTime
            ) {
                return
            }

            Write-Verbose '[Connect-AzA_AzAccount]: - Running in Azure Automation - Generating connection environment variables'

            if ([string]::IsNullOrEmpty($env:MG_PRINCIPAL_DISPLAYNAME)) {
                Throw '[Connect-AzA_AzAccount]: - Missing environment variable $env:MG_PRINCIPAL_DISPLAYNAME. Please run Connect-AzA_MgGraph first.'
            }

            #region [COMMON] ENVIRONMENT ---------------------------------------------------
            if ($null -eq (Get-Module -Name Orchestrator.AssetManagement.Cmdlets -ErrorAction SilentlyContinue)) {
                try {
                    $PSModuleAutoloadingPreference = 'All'
                    $null = Get-AutomationVariable -Name DummyVar -ErrorAction SilentlyContinue -WhatIf
                }
                catch {
                    # Do nothing. We just want to trigger auto import of Orchestrator.AssetManagement.Cmdlets
                    Throw '[Connect-AzA_AzAccount]: - Unable to import module Orchestrator.AssetManagement.Cmdlets'
                }
            }

            $apiVersion = '2023-11-01'
            #endregion ---------------------------------------------------------------------

            try {
                $AzAutomationAccount = ((Az.Accounts\Invoke-AzRestMethod -Path "/subscriptions/$((Az.Accounts\Get-AzContext).Subscription.Id)/providers/Microsoft.Automation/automationAccounts?api-version=$apiVersion" -ErrorAction Stop).Content | ConvertFrom-Json).Value | Where-Object { $_.name -eq $env:MG_PRINCIPAL_DISPLAYNAME }
                if ($AzAutomationAccount) {
                    Write-Verbose '[Connect-AzA_AzAccount]: - Retrieved Automation Account details'
                    $null, $null, $subscriptionId, $null, $resourceGroupName, $null, $null, $null, $automationAccountName = $AzAutomationAccount.id -split '/'
                    [Environment]::SetEnvironmentVariable('AZURE_AUTOMATION_AccountId', $AzAutomationAccount.id)
                    [Environment]::SetEnvironmentVariable('AZURE_AUTOMATION_SubscriptionId', $subscriptionId)
                    [Environment]::SetEnvironmentVariable('AZURE_AUTOMATION_ResourceGroupName', $resourceGroupName)
                    [Environment]::SetEnvironmentVariable('AZURE_AUTOMATION_AccountName', $automationAccountName)
                    [Environment]::SetEnvironmentVariable('AZURE_AUTOMATION_IDENTITY_PrincipalId', $AzAutomationAccount.Identity.PrincipalId)
                    [Environment]::SetEnvironmentVariable('AZURE_AUTOMATION_IDENTITY_TenantId', $AzAutomationAccount.Identity.TenantId)
                    [Environment]::SetEnvironmentVariable('AZURE_AUTOMATION_IDENTITY_Type', $AzAutomationAccount.Identity.Type)

                    if ($IsAzureAutomationJob) {

                        $AzAutomationJob = (Az.Accounts\Invoke-AzRestMethod -Path "$($AzAutomationAccount.id)/jobs/$($PSPrivateMetadata.JobId)?api-version=$apiVersion" -ErrorAction Stop).Content | ConvertFrom-Json
                        if ($AzAutomationJob) {
                            Write-Verbose '[Connect-AzA_AzAccount]: - Retrieved Automation Job details'
                            [Environment]::SetEnvironmentVariable('AZURE_AUTOMATION_RUNBOOK_Name', $AzAutomationJob.properties.runbook.name)
                            [Environment]::SetEnvironmentVariable('AZURE_AUTOMATION_RUNBOOK_JOB_CreationTime', [DateTime]::Parse($AzAutomationJob.properties.creationTime).ToUniversalTime())
                            [Environment]::SetEnvironmentVariable('AZURE_AUTOMATION_RUNBOOK_JOB_StartTime', [DateTime]::Parse($AzAutomationJob.properties.startTime).ToUniversalTime())

                            $AzAutomationRunbook = (Az.Accounts\Invoke-AzRestMethod -Path "$($AzAutomationAccount.id)/runbooks/$($AzAutomationJob.properties.runbook.name)?api-version=$apiVersion" -ErrorAction Stop).Content | ConvertFrom-Json
                            if ($AzAutomationRunbook) {
                                Write-Verbose '[Connect-AzA_AzAccount]: - Retrieved Automation Runbook details'
                                [Environment]::SetEnvironmentVariable('AZURE_AUTOMATION_RUNBOOK_CreationTime', [DateTime]::Parse($AzAutomationRunbook.properties.creationTime).ToUniversalTime())
                                [Environment]::SetEnvironmentVariable('AZURE_AUTOMATION_RUNBOOK_LastModifiedTime', [DateTime]::Parse($AzAutomationRunbook.properties.lastModifiedTime).ToUniversalTime())
                            }
                            else {
                                Throw "[Connect-AzA_AzAccount]: - Unable to find own Automation Runbook details for runbook name '$($AzAutomationJob.properties.runbook.name)'"
                            }
                        }
                        else {
                            Throw "[Connect-AzA_AzAccount]: - Unable to find own Automation Job details for job Id $($PSPrivateMetadata.JobId)"
                        }
                    }
                    else {
                        Throw '[Connect-AzA_AzAccount]: - Missing global variable $PSPrivateMetadata.JobId'
                    }
                }
                else {
                    Throw "[Connect-AzA_AzAccount]: - Unable to find own Automation Account details for '$env:MG_PRINCIPAL_DISPLAYNAME'"
                }
            }
            catch {
                Throw "Error setting Azure Automation environment variables: $($_.Exception.Message)"
            }
        }
        else {
            Write-Verbose '[Connect-AzA_AzAccount]: - Not running in Azure Automation - no connection environment variables set.'
        }
    }
    #endregion ---------------------------------------------------------------------

    if (Az.Accounts\Get-AzContext) {
        if ($SetEnvVarsAfterMgConnect -eq $true) {
            try {
                Initialize-EnvVarsAfterMgConnect
            }
            catch {
                Az.Accounts\Disconnect-AzAccount -ErrorAction SilentlyContinue
                Throw $_
            }
        }
    }
    else {
        $Context = $null
        $params = @{
            Scope       = 'Process'
            ErrorAction = 'Stop'
            Confirm     = $false
            WhatIf      = $false
        }

        if ($IsAzureAutomationJob) {
            Write-Verbose '[Connect-AzA_AzAccount]: - Using system-assigned Managed Service Identity'
            $params.Identity = $true
        }
        elseif (
            $env:IS_DEV_CONTAINER -or
            $env:REMOTE_CONTAINERS -or
            $env:GITHUB_CODESPACE_TOKEN -or
            $env:AWS_CLOUD9_USER -or
            $IsNonUserInteractive
        ) {
            Write-Verbose '[Connect-AzA_AzAccount]: - Using device code authentication'
            $params.UseDeviceAuthentication = $true
        }
        else {
            Write-Verbose '[Connect-AzA_AzAccount]: - Using interactive sign in'
        }

        try {
            if ($Tenant) {
                if (
                    $Tenant -notmatch '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' -or
                    $Tenant -eq '00000000-0000-0000-0000-000000000000'
                ) {
                    Throw '[Connect-AzA_AzAccount]: - Invalid tenant ID. The tenant ID must be a valid GUID.'
                }
                $params.Tenant = $Tenant
            }
            if ($Subscription) {
                if (
                    $Subscription -notmatch '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' -or
                    $Subscription -eq '00000000-0000-0000-0000-000000000000'
                ) {
                    Throw '[Connect-AzA_AzAccount]: - Invalid subscription ID. The subscription ID must be a valid GUID.'
                }
                $params.Subscription = $Subscription
            }

            if (-not $params.UseDeviceAuthentication) {
                Write-Information 'Connecting to Microsoft Azure ...' -InformationAction Continue
            }
            $Context = (Az.Accounts\Connect-AzAccount @params).context

            if ($null -eq $Context.Subscription) {
                Az.Accounts\Disconnect-AzAccount -ErrorAction SilentlyContinue
                Throw '[Connect-AzA_AzAccount]: - No subscription found, or you do not have access to any subscriptions.'
            }
            if ($params.Subscription -and $params.Subscription -ne $Context.Subscription) {
                Az.Accounts\Disconnect-AzAccount -ErrorAction SilentlyContinue
                Throw "[Connect-AzA_AzAccount]: - Subscription '$($Context.Subscription)' does not match the specified subscription '$($params.Subscription)'."
            }
            $Context = Az.Accounts\Set-AzContext -SubscriptionName $Context.Subscription -DefaultProfile $Context

            if ($SetEnvVarsAfterMgConnect -eq $true) {
                Initialize-EnvVarsAfterMgConnect
            }
        }
        catch {
            Throw $_
        }
    }

    Write-AzA_FunctionEnd $MyInvocation -OnceOnly
}
