<#
.SYNOPSIS
    This command retrieves information about the current Azure Automation job.

.DESCRIPTION
    The command is designed to be used as a runbook within Azure Automation.
    It retrieves information about the current job, such as creation time, start time, automation account details, and runbook details.

    Note that the script will only work when Connect-AzA_AzAccount has been executed before as it relies on environment variables set by that script.
    Otherwise, the script will generate some dummy information, for example during local development.
#>

function Get-AzA_AzAutomationJobInfo {
    [CmdletBinding()]
    Param()

    Write-AzA_FunctionBegin $MyInvocation

    $return = @{
        CreationTime      = $null
        StartTime         = $null
        AutomationAccount = $null
        Runbook           = $null
    }

    if (
        $PSPrivateMetadata.JobId -and
        $env:AZURE_AUTOMATION_RUNBOOK_JOB_CreationTime -and
        $env:AZURE_AUTOMATION_RUNBOOK_JOB_StartTime -and
        $env:AZURE_AUTOMATION_AccountId
    ) {
        $return.JobId = $PSPrivateMetadata.JobId
        $return.CreationTime = [datetime]::Parse($env:AZURE_AUTOMATION_RUNBOOK_JOB_CreationTime).ToUniversalTime()
        $return.StartTime = [datetime]::Parse($env:AZURE_AUTOMATION_RUNBOOK_JOB_StartTime).ToUniversalTime()

        $return.AutomationAccount = @{
            SubscriptionId    = $env:AZURE_AUTOMATION_SubscriptionId
            ResourceGroupName = $env:AZURE_AUTOMATION_ResourceGroupName
            Name              = $env:AZURE_AUTOMATION_AccountName
            Identity          = @{
                PrincipalId = $env:AZURE_AUTOMATION_IDENTITY_PrincipalId
                TenantId    = $env:AZURE_AUTOMATION_IDENTITY_TenantId
                Type        = $env:AZURE_AUTOMATION_IDENTITY_Type
            }
        }
        $return.Runbook = @{
            Name             = $env:AZURE_AUTOMATION_RUNBOOK_Name
            CreationTime     = [datetime]::Parse($env:AZURE_AUTOMATION_RUNBOOK_CreationTime).ToUniversalTime()
            LastModifiedTime = [datetime]::Parse($env:AZURE_AUTOMATION_RUNBOOK_LastModifiedTime).ToUniversalTime()
        }

        $params = @{
            Path = "$($env:AZURE_AUTOMATION_AccountId)/runbooks/$($return.Runbook.Name)&api-version=2023-11-01"
        }
        $tags = (Invoke-AzA_AzRestMethod $params).Content.tags

        $return.Runbook.ScriptVersion = $tags.'Script.Version'
        $return.Runbook.ScriptGuid = $tags.'Script.Guid'
    }
    else {
        $return.CreationTime = [datetime]::UtcNow
        $return.StartTime = $return.CreationTime
        $return.Runbook = @{
            Name = (Get-Item $MyInvocation.PSCommandPath).BaseName
        }
    }

    Write-AzA_FunctionEnd $MyInvocation
    return $return
}
