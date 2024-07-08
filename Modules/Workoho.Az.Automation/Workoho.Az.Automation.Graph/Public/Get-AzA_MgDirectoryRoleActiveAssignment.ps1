<#
.SYNOPSIS
    Get active directory roles of current user

.DESCRIPTION
    This script retrieves the active directory roles assigned to the current user using the Microsoft Graph API.

.EXAMPLE
    PS> Get-AzA_MgDirectoryRoleActiveAssignment

    Retrieves the active directory roles assigned to the current user.
#>

function Get-AzA_MgDirectoryRoleActiveAssignment {
    [CmdletBinding()]
    Param()

    Write-AzA_FunctionBegin $MyInvocation

    # Avoid using Microsoft.Graph.Identity.Governance module as it requires too much memory in Azure Automation
    $params = @{
        Uri         = "/v1.0/roleManagement/directory/roleAssignments?`$filter=PrincipalId eq %27$($env:MG_PRINCIPAL_ID)%27&`$expand=roleDefinition"
        ErrorAction = 'Stop'
        Verbose     = $false
    }

    try {
        $return = (Invoke-MgGraphRequest @params).value
    }
    catch {
        Throw $_
    }

    Write-AzA_FunctionEnd $MyInvocation
    return $return
}
