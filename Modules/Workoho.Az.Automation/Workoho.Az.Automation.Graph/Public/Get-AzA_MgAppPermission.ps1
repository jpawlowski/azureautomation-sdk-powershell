<#
.SYNOPSIS
    Retrieves the application permissions and OAuth2 permission scopes for the specified applications.

.DESCRIPTION
    This script retrieves the application permissions and OAuth2 permission scopes for the specified applications.

.PARAMETER App
    Specifies the applications for which to retrieve the permissions and scopes. If not specified, all applications
    associated with the user or service principal will be considered.

.EXAMPLE
    PS> Get-MgAppPermission -App 'MyApp1', 'MyApp2'

    Retrieves the permissions and scopes for the applications 'MyApp1' and 'MyApp2'.
#>

function Get-AzA_MgAppPermission {
    [CmdletBinding()]
    [OutputType([System.Collections.ArrayList])]
    Param(
        [Array]$App
    )

    Write-AzA_FunctionBegin $MyInvocation

    try {
        $return = [System.Collections.ArrayList]::new()

        if ((Get-MgContext).AuthType -eq 'Delegated') {
            $AppRoleAssignments = @((Invoke-MgGraphRequest -Uri "/v1.0/users/$($env:MG_PRINCIPAL_ID)/appRoleAssignments" -ErrorAction SilentlyContinue -Verbose:$false).value)
            $PermissionGrants = @((Invoke-MgGraphRequest -Uri "/v1.0/users/$($env:MG_PRINCIPAL_ID)/oauth2PermissionGrants" -ErrorAction SilentlyContinue -Verbose:$false).value)
        }
        else {
            $AppRoleAssignments = @((Invoke-MgGraphRequest -Uri "/v1.0/servicePrincipals/$($env:MG_PRINCIPAL_ID)/appRoleAssignments" -ErrorAction SilentlyContinue -Verbose:$false).value)
            $PermissionGrants = @((Invoke-MgGraphRequest -Uri "/v1.0/servicePrincipals/$($env:MG_PRINCIPAL_ID)/oauth2PermissionGrants" -ErrorAction SilentlyContinue -Verbose:$false).value)
        }

        if ($null -eq $App) {
            $Apps = [System.Collections.ArrayList]::new()
            foreach ($Item in $AppRoleAssignments) {
                [void] $Apps.Add($Item.ResourceId)
            }
        }
        else {
            $Apps = $App | Select-Object -Unique
        }

        foreach ($Item in $Apps) {
            $DisplayName = $null
            $AppId = $null
            $AppResource = $null

            if ($Item -is [String]) {
                if ($Item -match '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$') {
                    $AppId = $Item
                }
                else {
                    $DisplayName = $Item
                }
            }
            elseif ($Item.AppId) {
                $AppId = $Item.AppId
            }
            elseif ($Item.DisplayName) {
                $DisplayName = $Item.DisplayName
            }

            if ($AppId) {
                $AppResource = @((Invoke-MgGraphRequest -Uri "/v1.0/servicePrincipals?`$filter=servicePrincipalType eq 'Application' and (id eq '$($AppId)' or appId eq '$($AppId)')" -Verbose:$false).value)
            }
            elseif ($DisplayName) {
                $AppResource = @((Invoke-MgGraphRequest -Uri "/v1.0/servicePrincipals?`$filter=servicePrincipalType eq 'Application' and displayName eq '$($DisplayName)'" -Verbose:$false).value)
            }

            if (-Not $AppResource) {
                Write-Warning "[COMMON]: - Unable to find application: $DisplayName $(if ($AppId) { $AppId })"
                continue
            }

            $AppRoles = [System.Collections.ArrayList]::new()
            if ($AppRoleAssignments) {
                foreach ($appRoleId in (($AppRoleAssignments | Where-Object resourceId -eq $AppResource.id).appRoleId | Select-Object -Unique)) {
                    [void] $AppRoles.Add(($AppResource.appRoles | Where-Object id -eq $appRoleId).value)
                }
            }

            $Oauth2PermissionScopes = @{}
            if ($PermissionGrants) {
                foreach ($Permissions in ($PermissionGrants | Where-Object resourceId -eq $AppResource.id)) {
                    foreach ($Permission in $Permissions) {
                        $PrincipalTypeName = 'Admin'
                        if ($Permission.consentType -ne 'AllPrincipals') {
                            $PrincipalTypeName = $Permission.principalId
                        }
                        $Permission.scope.Trim() -split ' ' | ForEach-Object {
                            if (-Not $Oauth2PermissionScopes.$PrincipalTypeName) {
                                $Oauth2PermissionScopes.$PrincipalTypeName = [System.Collections.ArrayList]::new()
                            }
                            [void] ($Oauth2PermissionScopes.$PrincipalTypeName).Add($_)
                        }
                    }
                }
            }

            [void] $return.Add(
                @{
                    AppId                  = $AppResource.appId
                    DisplayName            = $AppResource.displayName
                    AppRoles               = $AppRoles
                    Oauth2PermissionScopes = $Oauth2PermissionScopes
                }
            )
        }
    }
    catch {
        Throw $_
    }

    Write-AzA_FunctionEnd $MyInvocation
    return $return
}
