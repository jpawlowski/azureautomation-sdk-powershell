<#
.SYNOPSIS
    Write warning to warning stream and return back object

.DESCRIPTION
    This script is used to write a warning message to the warning stream and return back an object.
    This is a wrapper around Write-Warning cmdlet that returns the same message as an object so it can afterwards be added to a collection of warnings in your runbook.
    The collecation may be used to return all errors at once at the end of the runbook, for example when you want to send a response to a calling system using a webhook.

    The data structure generally follows more the one of the Write-Error cmdlet to allow adding more information for your calling system.
    The data that Write-Warning cmdlet will output is only the message property of the object.

.PARAMETER Param
    Specifies the parameter to be used for the warning message. It can be a string or an object.

.EXAMPLE
    PS> $Script:returnWarning = [System.Collections.ArrayList]::new()
    PS> [void] $Script:returnWarning.Add(( Write-AzA_Warning @{
                Message           = "Your warning message here."
                ErrorId           = '201'
                Category          = 'OperationStopped'
                TargetName        = $ReferralUserId
                TargetObject      = $null
                RecommendedAction = 'Try again later.'
                CategoryActivity  = 'Persisent Error'
                CategoryReason    = "No other items are processed due to persistent error before."
            }))

    This example outputs an warning message to the warning stream and adds the same message to the $Script:returnWarning collection.
#>

function Write-AzA_Warning {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        $Param
    )

    Write-AzA_FunctionBegin $MyInvocation -OnceOnly

    $params = if ($Param) {
        if ($Param -is [String]) {
            @{ Message = $Param }
        }
        else {
            $Param.Clone()
        }
    }
    else {
        @{}
    }
    if (-not [string]::IsNullOrEmpty($params.Message)) {
        Write-Warning -Message $($params.Message)
    }

    Write-AzA_FunctionEnd $MyInvocation -OnceOnly
    return $params
}
