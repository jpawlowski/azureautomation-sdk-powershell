<#
.SYNOPSIS
    Imports Azure Automation variables to PowerShell environment variables.

.DESCRIPTION
    This script is used to import Azure Automation variables to PowerShell environment variables.
    It connects to the Azure Automation account, retrieves the variables, and sets them as environment variables in the current PowerShell session.

    Note that only variables of type String are imported, variables of other types are skipped.
    This is because Azure Automation variables can be of multiple types, and only String values can be set for environment variables.

.PARAMETER Variable
    Specifies an array of variable names to import. If provided, only the specified variables will be imported. If not provided, all variables will be imported.

.EXAMPLE
    PS> Import-AzAutomationVariableToPSEnv -Variable "Variable1", "Variable2"

    Imports only the variables "Variable1" and "Variable2" from Azure Automation to PowerShell environment variables.
#>

function Import-Auto_AzAutomationVariableToPSEnv {
    [CmdletBinding()]
    Param(
        [Array]$Variable
    )

    Write-Auto_FunctionBegin $MyInvocation

    try {
        if ($IsAzureAutomationJob) {

            #region [COMMON] CONNECTIONS ---------------------------------------------------
            # Implicitly connect to Azure Graph API using the Connect-Auto_MgGraph command.
            # This will ensure the connections are established in the correct order, while still retrieving the necessary environment variables.
            Connect-Auto_MgGraph
            #endregion ---------------------------------------------------------------------

            if ([string]::IsNullOrEmpty($env:AZURE_AUTOMATION_AccountId)) {
                Throw 'Missing environment variable $env:AZURE_AUTOMATION_AccountId'
            }
            else {
                $retryCount = 0
                $success = $false
                $AutomationVariables = $null
                $lastError = $null
                $apiVersion = '2023-11-01'

                while (-not $success -and $retryCount -lt 5) {
                    try {
                        $params = @{
                            Path        = "$($env:AZURE_AUTOMATION_AccountId)/variables?api-version=$apiVersion"
                            ErrorAction = 'Stop'
                        }
                        $AutomationVariables = @((Invoke-Auto_AzRestMethod $params).Content.value)
                        $success = $true
                    }
                    catch {
                        $lastError = $_
                        $retryCount++
                        Start-Sleep -Seconds (5 * $retryCount) # exponential backoff
                    }
                }

                if (-not $success) {
                    throw "Failed to get automation variables after 5 attempts. Last error: $lastError"
                }
            }

            $AutomationVariables | & {
                process {
                    if ($_.Name -notmatch '^[a-zA-Z_][a-zA-Z0-9_]*$') {
                        Write-Warning "[COMMON]: - Skipping variable '$($_.Name)' because its name contains invalid characters, starts with a digit, or contains a space."
                        return
                    }
                    if (($null -ne $Script:Variable) -and ($_.Name -notin $Script:Variable)) { return }
                    if ($null -eq $_.properties.value) {
                        $_.properties | Add-Member -Type NoteProperty -Name value -Value ''
                    }
                    if (-not [string]::IsNullOrEmpty($_.properties.value)) {
                        $_.properties.value = [System.Text.RegularExpressions.Regex]::Unescape($_.properties.value.Trim('"'))
                    }
                    if ($_.properties.isEncrypted) {
                        # Get-AutomationVariable is an internal cmdlet that is not available in the Az module.
                        # It is part of the Automation internal module Orchestrator.AssetManagement.Cmdlets.
                        # https://learn.microsoft.com/en-us/azure/automation/shared-resources/modules#internal-cmdlets
                        $_.properties.value = Get-AutomationVariable -Name $_.Name
                    }

                    if ($_.properties.value -eq 'true' -or $_.properties.value -eq 'false') {
                        Write-Verbose "[COMMON]: - Setting `$env:$($_.Name) as boolean string value"
                        if ($_.properties.value -eq 'true') {
                            [Environment]::SetEnvironmentVariable($_.Name, 'True')
                        }
                        else {
                            [Environment]::SetEnvironmentVariable($_.Name, 'False')
                        }
                    }
                    elseif ([string]::new($_.properties.value).Length -gt 32767) {
                        Write-Verbose "[COMMON]: - SKIPPING variable '$($_.Name)' because it is too long"
                    }
                    elseif ([string]::new($_.properties.value) -eq '') {
                        Write-Verbose "[COMMON]: - Setting `$env:$($_.Name) as empty string value"
                        [Environment]::SetEnvironmentVariable($_.Name, "''")
                    }
                    else {
                        Write-Verbose "[COMMON]: - Setting `$env:$($_.Name) as string value"
                        [Environment]::SetEnvironmentVariable($_.Name, $_.properties.value)
                    }
                }
            }
            Write-Verbose "[COMMON]: - Successfully imported automation variables to PowerShell environment variables"
        }
        else {
            Write-Verbose "[COMMON]: - Running in local environment"
            if (Test-Path -Path "$PSScriptRoot/../scripts/AzAutoFWProject/Set-AzAutomationVariableAsPSEnv.ps1") {
                & "$PSScriptRoot/../scripts/AzAutoFWProject/Set-AzAutomationVariableAsPSEnv.ps1" -Variable $Variable -Verbose:$VerbosePreference
            }
            else {
                Write-Warning "[COMMON]: - Set-AzAutomationVariableAsPSEnv.ps1 not found in $PSScriptRoot/../scripts/AzAutoFWProject"
            }
        }
    }
    catch {
        Throw $_
    }

    Write-Auto_FunctionEnd $MyInvocation
}
