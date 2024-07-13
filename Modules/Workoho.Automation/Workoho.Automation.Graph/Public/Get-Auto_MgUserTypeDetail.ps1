<#
.SYNOPSIS
    This script retrieves detailed information about the user type based on the provided user object.

.DESCRIPTION
    The script takes an input parameter, UserObject, which represents the user object containing information about the user.
    It then determines various properties of the user, such as whether the user is an internal user, whether the user is authenticated using email OTP, Facebook, Google, Microsoft account, or external Azure AD, whether the user is federated, and the type of guest or external user.

    The resulting hash contains the following properties:
    - IsInternal: Indicates whether the user is an internal user.
    - IsEmailOTPAuthentication: Indicates whether the user is authenticated using email OTP.
    - IsSMSOTPAuthentication: Indicates whether the user is authenticated using SMS OTP.
    - IsFacebookAccount: Indicates whether the user is authenticated using a Facebook account.
    - IsGoogleAccount: Indicates whether the user is authenticated using a Google account.
    - IsMicrosoftAccount: Indicates whether the user is authenticated using a Microsoft account.
    - IsExternalEntraAccount: Indicates whether the user is authenticated using an external Azure AD account.
    - IsFederated: Indicates whether the user is federated.
    - GuestOrExternalUserType: Indicates the type of guest or external user.

    Each property is determined based on the information present in the UserObject. If a property is not applicable or cannot be determined, it will be set to $null.

.PARAMETER UserObject
    The user object containing information about the user.

.EXAMPLE
    PS> $UserObject = Get-MgUser -UserId 'john.doe@example.com'
    PS> Get-Auto_MgUserTypeDetail -UserObject $UserObject
#>

function Get-Auto_MgUserTypeDetail {
    [CmdletBinding()]
    Param(
        [Parameter(mandatory = $true)]
        [Object]$UserObject
    )

    Write-Auto_FunctionBegin $MyInvocation

    $return = @{
        IsInternal               = $null
        IsEmailOTPAuthentication = $null
        IsSMSOTPAuthentication   = $null
        IsFacebookAccount        = $null
        IsGoogleAccount          = $null
        IsMicrosoftAccount       = $null
        IsExternalEntraAccount   = $null
        IsFederated              = $null
        GuestOrExternalUserType  = $null
    }

    $identities = @($UserObject.Identities)

    if ($null -ne $UserObject.Identities -and $UserObject.Identities.Count -gt 0) {
        if (
        ($identities.Issuer -contains 'mail') -or
        ($identities.SignInType -contains 'emailAddress')
        ) {
            Write-Verbose '[COMMON]: - IsEmailOTPAuthentication'
            $return.IsEmailOTPAuthentication = $true
        }
        else {
            $return.IsEmailOTPAuthentication = $false
        }

        if ($identities.Issuer -contains 'phone') {
            Write-Verbose '[COMMON]: - IsSMSOTPAuthentication'
            $return.IsSMSOTPAuthentication = $true
        }
        else {
            $return.IsSMSOTPAuthentication = $false
        }

        if ($identities.Issuer -contains 'facebook.com') {
            Write-Verbose '[COMMON]: - IsFacebookAccount'
            $return.IsFacebookAccount = $true
        }
        else {
            $return.IsFacebookAccount = $false
        }

        if ($identities.Issuer -contains 'google.com') {
            Write-Verbose '[COMMON]: - IsGoogleAccount'
            $return.IsGoogleAccount = $true
        }
        else {
            $return.IsGoogleAccount = $false
        }

        if ($identities.Issuer -contains 'MicrosoftAccount') {
            Write-Verbose '[COMMON]: - IsMicrosoftAccount'
            $return.IsMicrosoftAccount = $true
        }
        else {
            $return.IsMicrosoftAccount = $false
        }

        if ($identities.Issuer -contains 'ExternalAzureAD') {
            Write-Verbose '[COMMON]: - ExternalAzureAD'
            $return.IsExternalEntraAccount = $true
        }
        else {
            $return.IsExternalEntraAccount = $false
        }

        if (
            $return.IsSMSOTPAuthentication -eq $false -and
            $identities.SignInType -contains 'federated'
        ) {
            Write-Verbose '[COMMON]: - IsFederated'
            $return.IsFederated = $true
        }
        else {
            $return.IsFederated = $false
        }
    }

    if (
    (-Not [string]::IsNullOrEmpty($UserObject.UserType)) -and
    (-Not [string]::IsNullOrEmpty($UserObject.UserPrincipalName))
    ) {
        if ($UserObject.UserType -eq 'Member') {
            if ($UserObject.UserPrincipalName -notmatch '^.+#EXT#@.+\.onmicrosoft\.com$') {
                $return.GuestOrExternalUserType = 'None'
            }
            else {
                $return.GuestOrExternalUserType = 'b2bCollaborationMember'
            }
        }
        elseif ($UserObject.UserType -eq 'Guest') {
            if ($UserObject.UserPrincipalName -notmatch '^.+#EXT#@.+\.onmicrosoft\.com$') {
                $return.GuestOrExternalUserType = 'internalGuest'
            }
            else {
                $return.GuestOrExternalUserType = 'b2bCollaborationGuest'
            }
        }
        else {
            $return.GuestOrExternalUserType = 'otherExternalUser'
        }
        Write-Verbose "[COMMON]: - GuestOrExternalUserType: $($return.GuestOrExternalUserType)"
    }

    if (
    ($return.IsEmailOTPAuthentication -eq $false) -and
    ($return.IsFacebookAccount -eq $false) -and
    ($return.IsGoogleAccount -eq $false) -and
    ($return.IsMicrosoftAccount -eq $false) -and
    ($return.IsExternalEntraAccount -eq $false) -and
    ($return.IsFederated -eq $false) -and
    ($return.GuestOrExternalUserType -eq 'None')
    ) {
        Write-Verbose "[COMMON]: - IsInternal: True"
        $return.IsInternal = $true
    }
    elseif (
    ($null -ne $return.IsEmailOTPAuthentication) -and
    ($null -ne $return.IsFacebookAccount) -and
    ($null -ne $return.IsGoogleAccount) -and
    ($null -ne $return.IsMicrosoftAccount) -and
    ($null -ne $return.IsExternalEntraAccount) -and
    ($null -ne $return.IsFederated) -and
    ($null -ne $return.GuestOrExternalUserType)
    ) {
        Write-Verbose "[COMMON]: - IsInternal: False"
        $return.IsInternal = $false
    }
    else {
        Write-Warning "[COMMON]: - IsInternal: UNKNOWN"
    }

    Write-Auto_FunctionEnd $MyInvocation
    return $return
}
