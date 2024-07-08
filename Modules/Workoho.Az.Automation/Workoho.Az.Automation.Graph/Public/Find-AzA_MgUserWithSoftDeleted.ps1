<#
.SYNOPSIS
    Find a user in Microsoft Graph including soft-deleted users.

.DESCRIPTION
    This script is used to find a user in Microsoft Graph including soft-deleted users.
    The script will expand the manager property by default, but you may specify which properties to return.

    In case the user cannot be found anymore, the script will return an empty object.
    The script will only throw an exception if any other error occurs.
    This way, one can be sure that if no user was found, it is not due to an error, but because the user does not exist.

.PARAMETER UserId
    The user ID or user principal name of the user to search for.
    May be an array, or a comma-separated string of object ID, user principal name, or onPremisesSamAccountName.

.PARAMETER Property
    The properties to return for the user.

    Note that when you request the signInActivity property, it is only available for users with an Entra ID Premium P1 license, and requires at least Reports Reader role when working with delegated permissions.
    You may use the Confirm-AzA_MgDirectoryRoleActiveAssignment function in your runbook to check if the role is assigned.

.PARAMETER ExpandProperty
    The user properties to expand.

.PARAMETER OutputType
    The output type of the result. Default is Hashtable.
#>

function Find-AzA_MgUserWithSoftDeleted {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [array] $UserId,
        [array] $Property,
        [array] $ExpandProperty,
        [string] $OutputType
    )

    Write-AzA_FunctionBegin $MyInvocation

    @($UserId) | ForEach-Object { ($_ -replace '\s', '').Split(',') } | ForEach-Object {
        if (
            $_ -eq $null -or
            $_ -eq '00000000-0000-0000-0000-000000000000'
        ) {
            Throw 'User ID must not be null or empty.'
        }

        $filter = if ($_ -match '^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$') {
            "id eq '$_'"
        }
        elseif ($_ -contains '@') {
            "userPrincipalName eq '$([System.Web.HttpUtility]::UrlEncode($_))'"
        }
        else {
            "onPremisesSamAccountName eq '$_'"
        }

        if ($null -ne $Property) {
            $Property = '&$select=' + ($Property -join ',')
        }

        if ($null -ne $ExpandProperty) {
            $ExpandProperty = '&$expand=' + (
                @(
                    @($ExpandProperty).GetEnumerator() | & {
                        process {
                            if ($_ -is [string]) {
                                $_
                            }
                            elseif ($_ -is [hashtable]) {
                                $h = $_
                                $_.Keys | & {
                                    process {
                                        '{0}($select={1})' -f $_, ($h.$_ -join ',')
                                    }
                                }
                            }
                        }
                    }
                ) -join ','
            )
        }

        $params = @{
            Method      = 'POST'
            Uri         = '/v1.0/$batch'
            Body        = @{
                requests = [System.Collections.ArrayList] @(
                    # First, search in existing users. We're using $filter here because fetching the user by Id would return an error if the user is soft-deleted or not existing.
                    @{
                        id     = 1
                        method = 'GET'
                        url    = 'users?$filter={0}{1}{2}' -f $filter, $Property, $ExpandProperty
                    }

                    # If not found, search in deleted items. We're using $filter here because fetching the user by Id would return an error if the user is not existing.
                    @{
                        id     = 2
                        method = 'GET'
                        url    = 'directory/deletedItems/microsoft.graph.user?$filter={0}{1}{2}' -f $filter, $Property, $ExpandProperty
                    }
                )
            }
            ErrorAction = 'Stop'
            Verbose     = $VerbosePreference
            Debug       = $DebugPreference
        }

        if ($OutputType) {
            $params.OutputType = $OutputType
        }

        $retryAfter = $null

        try {
            $response = Invoke-AzA_MgGraphRequest $params
        }
        catch {
            Throw $_
        }

        while ($response) {
            $response.responses | Sort-Object -Property Id | & {
                process {
                    if ($_.status -eq 429) {
                        $retryAfter = if (-not $retryAfter -or $retryAfter -gt $_.Headers.'Retry-After') { [int] $_.Headers.'Retry-After' }
                    }
                    elseif ($_.status -eq 200 -or $_.status -eq 404) {
                        $responseId = $_.Id

                        if ($null -ne $_.body.value) {
                            @($_.body.value)[0]
                        }

                        $requestIndexId = $params.Body.requests.IndexOf(($params.Body.requests | Where-Object { $_.id -eq $responseId }))
                        $params.Body.requests.RemoveAt($requestIndexId)
                    }
                    else {
                        Throw "Error $($_.status): [$($_.body.error.code)] $($_.body.error.message)"
                    }
                }
            }

            if ($params.Body.requests.Count -gt 0) {
                if ($retryAfter) {
                    Write-Verbose "[Find-MgUserWithSoftDeleted]: - Rate limit exceeded, waiting for $retryAfter seconds..."
                    Start-Sleep -Seconds $retryAfter
                }
                try {
                    $response = Invoke-AzA_MgGraphRequest $params
                }
                catch {
                    Throw $_
                }
            }
            else {
                $response = $null
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()
            }
        }
    }

    Write-AzA_FunctionEnd $MyInvocation
}
