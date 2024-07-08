<#
.SYNOPSIS
    Validate if current application has assigned the listed app roles in Microsoft Entra

.DESCRIPTION
    Common runbook that can be used by other runbooks. It can not be started as an Azure Automation job directly.

.PARAMETER Permissions
    Collection of Apps and their desired permissions. A hash object may look like:

    @{
        [System.String]DisplayName = <DisplayName>
        [System.String]AppId = <roleTemplateId>
        AppRoles = @(
            'Directory.Read.All'
            'User.Read.All'
        )
        Oauth2PermissionScopes = @{
            Admin = @(
                'offline_access'
                'openid'
                'profile'
            )
            '<User-ObjectId>' = @(
            )
        }
    }
#>

function Confirm-AzA_MgAppPermission {
    [CmdletBinding()]
    Param(
        [Parameter(mandatory = $true)]
        [Array]$Permissions
    )

    Write-AzA_FunctionBegin $MyInvocation

    $AppPermissions = Get-AzA_MgAppPermission

    foreach ($Permission in ($Permissions | Select-Object -Unique)) {
        #TODO
    }

    Write-AzA_FunctionEnd $MyInvocation
}
