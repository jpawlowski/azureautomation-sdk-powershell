<#
.SYNOPSIS
    Convert user IDs like user@example.com to a local User Principal Name of the tenant like user_example.com#EXT@tenant.onmicrosoft.com.

.DESCRIPTION
    This script takes an array of user IDs and converts them to local User Principal Names based on the tenant's default verified domain.
    This is useful to convert login names or email addresses that external users use to sign in and retreive emails to the actual UPNs of their corresponding guest accounts in the tenant.
    The local UPN can then be used as -UserId parameter for Microsoft Graph API calls.

    The conversion rules are as follows:
    - If the input is a valid GUID, it is returned as is.
    - If the input is in the format "user_externalDomain#EXT#@localDomain", but the external domain is actually a verified domain of the tenant, it is converted to a local UPN "user@externalDomain".
    - If the input is in the format "user_externalDomain#EXT#@localDomain", and localDomain is a verified domain of the tenant, it is returned as is.
    - If the input is in the format "user_externalDomain#EXT#@localDomain", but neither externalDomain nor localDomain are verified domains of the tenant, it is converted to a local UPN "user_externalDomain#EXT@tenantDomain".
    - If the input is in the format "user@externalDomain", and externalDomain is a verified domain of the tenant, it is returned as is.
    - If the input is in the format "user@externalDomain", but externalDomain is not a verified domain of the tenant, it is converted to a local UPN "user_externalDomain#EXT@tenantDomain".

.PARAMETER UserId
    The array of user IDs to be converted.

.PARAMETER VerifiedDomains
    The object containing the verified domains. If not provided, the script will connect to Microsoft Graph to retrieve the verified domains of the current tenant.

.EXAMPLE
    PS> Convert-Auto_UserIdToLocalUserId -UserId 'john.doe@contoso.com', 'jane.doe@example.com'

    This example demonstrates how to convert an array of user IDs to local UPNs using the tenant's default verified domain.
#>

function Convert-Auto_UserIdToLocalUserId {
    [CmdletBinding()]
    Param(
        [Parameter(mandatory = $true)]
        [Array]$UserId,
        [Object]$VerifiedDomains
    )

    Write-Auto_FunctionBegin $MyInvocation

    $return = [System.Collections.ArrayList]::new($UserId.Count)

    $tenantVerifiedDomains = if ($VerifiedDomains) { $VerifiedDomains } else {
        #region [COMMON] OPEN CONNECTIONS: Microsoft Graph -----------------------------
        Connect-Auto_MgGraph -Scopes @(
            'Organization.Read.All'
        )
        #endregion ---------------------------------------------------------------------

        try {
        (Invoke-Auto_MgGraphRequest @{ Uri = '/v1.0/organization'; ErrorAction = 'Stop'; Verbose = $false; Debug = $false }).Value.VerifiedDomains
        }
        catch {
            Throw $_
        }
    }
    $tenantDomain = ($tenantVerifiedDomains | Where-Object { $_.IsInitial -eq $true }).Name

    $UserId | & {
        process {
            if ($_.GetType().Name -ne 'String') {
                Write-Error "[COMMON]: - Input array UserId contains item of type $($_.GetType().Name)"
                return
            }
            if ([string]::IsNullOrEmpty( $_.Trim() )) {
                Write-Error '[COMMON]: - Input array UserId contains IsNullOrEmpty string'
                return
            }
            switch -Regex ( $_.Trim() ) {
                '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$' {
                    [void] $Script:return.Add($_)
                    break
                }
                "^(.+)_([^_]+\..+)#EXT#@(.+)$" {
                    if ($Matches[2] -in $tenantVerifiedDomains.Name) {
                        $UPN = "$( ($Matches[1]).ToLower() )@$( ($Matches[2]).ToLower() )"
                        [void] $Script:return.Add($UPN)
                        Write-Verbose "[COMMON]: - $_ > $UPN (Uses a verified domain of this tenant, but was provided in external format)"
                    }
                    elseif ($Matches[3] -in $tenantVerifiedDomains.Name) {
                        $UPN = $_.ToLower()
                        Write-Verbose "[COMMON]: - $_ > $UPN (Already in external format)"
                        [void] $Script:return.Add($UPN)
                    }
                    else {
                        $UPN = "$( ($Matches[1]).ToLower() )_$( ($Matches[2]).ToLower() )#EXT#@$( $Script:tenantDomain )"
                        [void] $Script:return.Add($UPN)
                        Write-Verbose "[COMMON]: - $_ > $UPN (Uses an external domain in external format)"
                    }
                    break
                }
                '^([^\s]+)@([^\s]+\.[^\s]+)$' {
                    if ($Matches[2] -in $tenantVerifiedDomains.Name) {
                        $UPN = $_.ToLower()
                        Write-Verbose "[COMMON]: - $_ > $UPN (Uses a verified domain of this tenant)"
                        [void] $Script:return.Add($UPN)
                    }
                    else {
                        $UPN = "$( ($Matches[1]).ToLower() )_$( ($Matches[2]).ToLower() )#EXT#@$($Script:tenantDomain)"
                        [void] $Script:return.Add($UPN)
                        Write-Verbose "[COMMON]: - $_ > $UPN (Uses an external domain)"
                    }
                    break
                }
                default {
                    Write-Warning "[COMMON]: - Could not convert $_ to local User Principal Name."
                    [void] $Script:return.Add($_)
                    break
                }
            }
        }
    }

    Write-Auto_FunctionEnd $MyInvocation
    return $return.ToArray()
}
