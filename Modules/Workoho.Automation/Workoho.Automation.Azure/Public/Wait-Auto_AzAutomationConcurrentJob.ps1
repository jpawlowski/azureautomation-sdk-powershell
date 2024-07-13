<#
.SYNOPSIS
    This script is used to wait for concurrent jobs in Azure Automation.

.DESCRIPTION
    This script checks for the presence of concurrent jobs in Azure Automation and waits until the current job is at the top of the queue.

.EXAMPLE
    PS> Wait-Auto_AzAutomationConcurrentJob

    Waits for concurrent jobs in Azure Automation.
#>

function Wait-Auto_AzAutomationConcurrentJob {
    [CmdletBinding()]
    Param()

    Write-Auto_FunctionBegin $MyInvocation

    if ($IsAzureAutomationJob) {

        #region [COMMON] CONNECTIONS ---------------------------------------------------
        # Implicitly connect to Azure Graph API using the Connect-Auto_MgGraph command.
        # This will ensure the connections are established in the correct order, while still retrieving the necessary environment variables.
        Connect-Auto_MgGraph
        #endregion ---------------------------------------------------------------------

        if ([string]::IsNullOrEmpty($env:AZURE_AUTOMATION_ResourceGroupName)) {
            Throw 'Missing environment variable $env:AZURE_AUTOMATION_ResourceGroupName.'
        }
        if ([string]::IsNullOrEmpty($env:AZURE_AUTOMATION_AccountName)) {
            Throw 'Missing environment variable $env:AZURE_AUTOMATION_AccountName.'
        }
        if ([string]::IsNullOrEmpty($env:AZURE_AUTOMATION_RUNBOOK_Name)) {
            Throw 'Missing environment variable $env:AZURE_AUTOMATION_RUNBOOK_Name.'
        }

        if ($env:AZURE_AUTOMATION_ResourceGroupName -and $env:AZURE_AUTOMATION_AccountName -and $env:AZURE_AUTOMATION_RUNBOOK_Name) {

            $DoLoop = $true
            $RetryCount = 1
            $MaxRetry = 300
            $WaitMin = 25000
            $WaitMax = 30000
            $WaitStep = 100
            $warningInterval = 180  # 3 minutes / 1 second sleep
            $warningCounter = $warningInterval  # Start with a warning after the first sleep

            do {
                $activeJobs = New-Object System.Collections.ArrayList

                try {
                    # Get all jobs for the runbook and process using pipeline to avoid memory issues
                    $params = @{
                        Path        = "$($env:AZURE_AUTOMATION_AccountId)/jobs?api-version=2023-11-01"
                        ErrorAction = 'Stop'
                        Verbose     = $false
                        Debug       = $false
                    }
                (Invoke-Auto_AzRestMethod $params).Content.value.properties |
                    & {
                        process {
                            if (
                                $_.status -eq 'Running' -or
                                $_.status -eq 'Queued' -or
                                $_.status -eq 'New' -or
                                $_.status -eq 'Activating' -or
                                $_.status -eq 'Resuming'
                            ) {
                                [void] $activeJobs.Add(
                                    @{
                                        jobId        = $_.jobId
                                        creationTime = [DateTime]::Parse($_.creationTime).ToUniversalTime()
                                    }
                                )
                            }
                        }
                    }
                }
                catch {
                    Throw $_
                }

                $activeJobs = @($activeJobs | Sort-Object -Property creationTime)
                $currentJob = $activeJobs | Where-Object { $_.jobId -eq $PSPrivateMetadata.JobId }

                if ($null -eq $currentJob) {
                    $waitTime = $((Get-Random -Minimum (3000 / $WaitStep) -Maximum (8000 / $WaitStep)) * $WaitStep)
                    $waitTimeInSeconds = [Math]::Round($waitTime / 1000, 2)
                    Write-Warning "[INFO]: - Current job not found (yet) in the list of active jobs. Waiting for $waitTimeInSeconds seconds to appear."
                    Start-Sleep -Milliseconds $waitTime
                }
                elseif ($currentJob.jobId -eq $activeJobs[0].jobId) {
                    Write-Verbose "[INFO]: - Current job is at the top of the queue."
                    $DoLoop = $false
                    $return = $true
                }
                elseif ($RetryCount -ge $MaxRetry) {
                    Write-Warning "[INFO]: - Maximum retry count reached. Exiting loop."
                    $DoLoop = $false
                    $return = $false
                }
                else {
                    $RetryCount++
                    $waitTime = $((Get-Random -Minimum ($WaitMin / $WaitStep) -Maximum ($WaitMax / $WaitStep)) * $WaitStep)
                    $waitTimeInSeconds = [Math]::Round($waitTime / 1000, 2)
                    $warningCounter += $waitTimeInSeconds
                    $rank = 1
                    for ($i = 0; $i -lt $activeJobs.Length; $i++) {
                        if ($activeJobs[$i].jobId -eq $currentJob.jobId) {
                            $rank = $i + 1
                            break
                        }
                    }
                    if ($warningCounter -ge $warningInterval) {
                        Write-Warning "[INFO]: - Waiting for concurrent jobs: I am at rank $($rank) out of $($activeJobs.Count) active jobs. Waiting for $waitTimeInSeconds seconds. Next status update will be in $warningInterval seconds."
                        $warningCounter = 0
                    }
                    else {
                        Write-Verbose "[INFO]: - Waiting for concurrent jobs: I am at rank $($rank) out of $($activeJobs.Count) active jobs. Waiting for $waitTimeInSeconds seconds."
                    }
                    Start-Sleep -Milliseconds $waitTime
                }

                Clear-Variable -Name activeJobs
                Clear-Variable -Name currentJob
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()
            } while ($DoLoop)
        }
    }
    else {
        Write-Verbose '[COMMON]: - Not running in Azure Automation: Concurrency check NOT ACTIVE.'
        $return = $true
    }

    Write-Auto_FunctionEnd $MyInvocation
    return $return
}
