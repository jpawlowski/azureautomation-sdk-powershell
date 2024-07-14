<#
.SYNOPSIS
    Convert local User Principal Name like user@contoso.com or user_contoso.com#EXT#@tenant.onmicrosoft.com to a user name like user@contoso.com.

.DESCRIPTION
    This script converts local User Principal Names (UPNs) to user names. It takes an array of UPNs as input and returns an array of corresponding user names.
    This is useful to convert UPNs of external users to the actual login names the users use to sign in and retreive emails.

    The conversion rules are as follows:
    - If the input is a valid GUID, it is returned as is.
    - If the input is in the format "username_domain#EXT#@tenant", it is converted to "username@domain".
    - If the input is in the format "username@domain", it is returned as is.
    - If the input does not match any of the above formats, a warning is issued and the input is returned as is.

.PARAMETER UserId
    Specifies an array of User Principal Names (UPNs) to be converted to user names.

.EXAMPLE
    PS> Convert-Auto_LocalUserIdToUserId -UserId "user1@contoso.com", "user2_contoso.com#EXT#@tenant.onmicrosoft.com"

    This example converts two UPNs to user names and returns the result.
#>

function Convert-Auto_LocalUserIdToUserId {
    [CmdletBinding()]
    Param(
        [Parameter(mandatory = $true)]
        [Array]$UserId
    )

    Write-Auto_FunctionBegin $MyInvocation

    $return = [System.Collections.ArrayList]::new($UserId.Count)

    $UserId | & {
        process {
            if ($_.GetType().Name -ne 'String') {
                Write-Error "[COMMON]: - Input array UserId contains item of type $($_.GetType().Name)"
                return
            }
            if ([string]::IsNullOrEmpty($_)) {
                Write-Error '[COMMON]: - Input array UserId contains IsNullOrEmpty string'
                return
            }
            switch -Regex ($_) {
                '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$' {
                    [void] $Script:return.Add($_)
                    break
                }
                "^(.+)_([^_]+\..+)#EXT#@(.+)$" {
                    [void] $Script:return.Add( "$(($Matches[1]).ToLower())@$(($Matches[2]).ToLower())" )
                    break
                }
                '^(.+)@(.+)$' {
                    [void] $Script:return.Add($_)
                    break
                }
                default {
                    Write-Warning "[COMMON]: - Could not convert $_ to user name."
                    [void] $Script:return.Add($_)
                    break
                }
            }
        }
    }

    Write-Auto_FunctionEnd $MyInvocation
    return $return.ToArray()
}
