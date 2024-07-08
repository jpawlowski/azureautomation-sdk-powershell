<#
.SYNOPSIS
    Write information to information stream and return back object

.DESCRIPTION
    This script is used to write information to the information stream and return back an object.
    This is a wrapper around Write-Information cmdlet that returns the same message as an object so it can afterwards be added to a collection of informations in your runbook.
    The collecation may be used to return all errors at once at the end of the runbook, for example when you want to send a response to a calling system using a webhook.

    The data structure generally follows more the one of the Write-Error cmdlet to allow adding more information for your calling system.
    The data that Write-Information cmdlet will output is only the message property of the object.

.PARAMETER Param
    Specifies the parameter to be used for the information message. It can be a string or an object.

.EXAMPLE
    PS> $Script:returnInformation = [System.Collections.ArrayList]::new()
    PS> [void] $Script:returnInformation.Add(( Write-AzA_Information @{
                Message           = "Your information message here."
                Category         = 'NotEnabled'
                TargetName       = $refUserObj.UserPrincipalName
                TargetObject     = $refUserObj.Id
                TargetType       = 'UserId'
                CategoryActivity = 'Account Provisioning'
                CategoryReason   = 'Your Reason.'
                Tags             = 'UserId', 'Account Provisioning'
            }))

    This example outputs an information message to the information stream and adds the same message to the $Script:returnInformation collection.
#>

function Write-AzA_Information {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        $Param
    )

    Write-AzA_FunctionBegin $MyInvocation -OnceOnly

    $params = if ($Param) {
        if ($Param -is [String]) {
            @{ MessageData = $Param }
        }
        else {
            $Param.Clone()
        }
    }
    else {
        @{}
    }

    if (-Not $params.MessageData -and $params.Message) {
        $params.MessageData = $params.Message
        $params.Remove('Message')
    }
    $iparams = @{}
    $params.Keys | & {
        process {
            if ($_ -notin 'MessageData', 'Tags', 'InformationAction') { return }
            $iparams.$_ = $params.$_
        }
    }
    $params.Message = $params.MessageData
    $params.Remove('MessageData')

    Write-Information @iparams

    Write-AzA_FunctionEnd $MyInvocation -OnceOnly
    return $params
}
