<#
.SYNOPSIS
    Write error to error stream and return back object

.DESCRIPTION
    This script is used to write an error to the error stream and return an object back an object.
    This is a wrapper around Write-Error cmdlet that returns the same message as an object so it can afterwards be added to a collection of errors in your runbook.
    The collecation may be used to return all errors at once at the end of the runbook, for example when you want to send a response to a calling system using a webhook.

.PARAMETER Param
    Specifies the parameter to be used for the error message. It can be a string or an object.

.EXAMPLE
    PS> $Script:returnError = [System.Collections.ArrayList]::new()
    PS> [void] $Script:returnError.Add(( Write-Auto_Error @{
                Message           = "Your error message here."
                ErrorId           = '500'
                Category          = 'OperationStopped'
                TargetName        = $ReferralUserId
                TargetObject      = $null
                RecommendedAction = 'Try again later.'
                CategoryActivity  = 'Persisent Error'
                CategoryReason    = "No other items are processed due to persistent error before."
            }))

    This example outputs an error message to the error stream and adds the same message to the $Script:returnError collection.
#>

function Write-Auto_Error {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        $Param
    )

    Write-Auto_FunctionBegin $MyInvocation -OnceOnly

    $return = if ($Param) {
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

    Write-Error @return

    Write-Auto_FunctionEnd $MyInvocation -OnceOnly
    return $return
}
