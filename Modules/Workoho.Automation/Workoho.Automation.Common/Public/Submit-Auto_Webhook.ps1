<#
.SYNOPSIS
    Send data to web service

.DESCRIPTION
    This script sends data to a web service using the specified URI and request body. It supports converting the body to different formats such as HTML, JSON, and XML. The script is designed to be used as a runbook and should not be run directly.

.PARAMETER Uri
    The URI of the web service to send the request to.

.PARAMETER Body
    The request body to send to the web service.

.PARAMETER Param
    Optional. Additional parameters to include in the web request.

.PARAMETER ConvertTo
    Optional. The format to convert the request body to. Supported values are 'Html', 'Json', 'Xml', where 'Json' is the default.

.PARAMETER ConvertToParam
    Optional. Additional parameters to pass to the conversion cmdlets.

.OUTPUTS
    The response from the web service.

.EXAMPLE
    PS> Submit-Auto_Webhook -Uri 'https://example.com/webhook' -Body 'Hello, world!' -ConvertTo 'Json'

    Sends a JSON-formatted request body to the specified URI.
#>

function Submit-Auto_Webhook {
    [CmdletBinding()]
    Param(
        [Parameter(mandatory = $true)]
        [String]$Uri,

        [Parameter(mandatory = $true)]
        [String]$Body,

        [Hashtable]$Param,
        [String]$ConvertTo = 'Json',
        [Hashtable]$ConvertToParam
    )

    Write-Auto_FunctionBegin $MyInvocation

    $WebRequestParams = if ($Param) { $Param.Clone() } else { @{} }
    $WebRequestParams.Uri = $Uri

    if (-Not $WebRequestParams.Method) { $WebRequestParams.Method = 'POST' }
    if (-Not $WebRequestParams.UseBasicParsing) { $WebRequestParams.UseBasicParsing = $true }

    $ConvertToParams = if ($ConvertToParam) { $ConvertToParam.Clone() } else { @{} }

    Switch ($ConvertTo) {
        'Html' {
            $WebRequestParams.Body = $Body | ConvertTo-Html @ConvertToParams
        }
        'Json' {
            if ($null -eq $ConvertToParams.Depth) { $ConvertToParams.Depth = 100 }
            if ($null -eq $ConvertToParams.Compress) { $ConvertToParams.Compress = $true }
            $WebRequestParams.Body = $Body | ConvertTo-Json @ConvertToParams
        }
        'Xml' {
            if ($null -eq $ConvertToParams.Depth) { $ConvertToParams.Depth = 100 }
            $WebRequestParams.Body = $Body | ConvertTo-Xml @ConvertToParams
        }
        default {
            $WebRequestParams.Body = $Body
        }
    }

    $return = Invoke-WebRequest @WebRequestParams

    Write-Auto_FunctionEnd $MyInvocation
    return $return
}
