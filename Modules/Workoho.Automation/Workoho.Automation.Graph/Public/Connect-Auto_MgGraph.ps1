<#
.SYNOPSIS
    Connects to Microsoft Graph and performs authorization checks.

.DESCRIPTION
    This script connects to Microsoft Graph using the specified scopes and performs authorization checks to ensure that the required scopes are available.

    The script also creates the following environment variables so that other scripts can use them:
    - $env:MG_PRINCIPAL_TYPE: The type of the principal ('Delegated' or 'Application').
    - $env:MG_PRINCIPAL_ID: The ID of the principal.
    - $env:MG_PRINCIPAL_DISPLAYNAME: The display name of the principal.

    This is in particular useful during local development when an interactive account is used, while in Azure Automation, a service principal is used.
    By using the environment variables, other scripts can easily determine the type of the principal and use the principal ID and display name without having to call Microsoft Graph again.

.PARAMETER Scopes
    An array of Microsoft Graph scopes required for the script.

.PARAMETER TenantId
    The ID of the tenant to connect to.

.EXAMPLE
    PS> Connect-Auto_MgGraph -Scopes @('User.Read', 'Mail.Read') -TenantId 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

    Connects to Microsoft Graph using the specified scopes and the specified tenant ID.
#>

function Connect-Auto_MgGraph {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Required for device code authentication.')]
    [CmdletBinding()]
    Param(
        [Array]$Scopes,
        [string]$TenantId
    )

    Write-Auto_FunctionBegin $MyInvocation -OnceOnly

    Import-Auto_Module @(
        @{ Name = 'Microsoft.Graph.Authentication'; MinimumVersion = '2.0'; MaximumVersion = '2.65535' }
    )

    function Get-MgMissingScope ([Array]$Scopes) {
        $MissingScopes = [System.Collections.ArrayList]::new()

        foreach ($Scope in $Scopes) {
            if ($WhatIfPreference -and ($Scope -like '*Write*')) {
                Write-Verbose "[Connect-Auto_MgGraph]: - What If: Removed $Scope from required Microsoft Graph scopes"
                [void] $Script:Scopes.Remove($Scope)
            }
            elseif ($Scope -notin @((Get-MgContext).Scopes)) {
                [void] $MissingScopes.Add($Scope)
            }
        }
        return $MissingScopes
    }

    $params = @{
        NoWelcome    = $true
        ContextScope = 'Process'
        ErrorAction  = 'Stop'
    }
    if ($TenantId) {
        if (
            $TenantId -notmatch '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' -or
            $TenantId -eq '00000000-0000-0000-0000-000000000000'
        ) {
            Throw '[Connect-Auto_MgGraph]: - Invalid tenant ID. The tenant ID must be a valid GUID.'
        }
        $params.TenantId = $TenantId
    }

    if (
        -Not (Get-MgContext) -or
        (
            $null -ne $params.TenantId -and
            $params.TenantId -ne (Get-MgContext).TenantId
        )
    ) {
        if ($IsAzureAutomationJob) {
            Write-Verbose '[Connect-Auto_MgGraph]: - Using system-assigned Managed Service Identity'
            $params.Identity = $true
        }
        elseif ($IsNonUserInteractive) {
            Throw '[Connect-Auto_MgGraph]: - Non-interactive mode is not supported for Microsoft Graph connection.'
        }
        elseif ($IsContainerized) {
            Write-Verbose '[Connect-Auto_MgGraph]: - Using device code authentication'
            $params.UseDeviceCode = $true
            if ($Scopes) { $params.Scopes = $Scopes }
        }
        else {
            Write-Verbose '[Connect-Auto_MgGraph]: - Using interactive sign in'
            if ($Scopes) { $params.Scopes = $Scopes }
        }

        try {
            if ($params.UseDeviceCode) {
                Write-Host "Please select the account you want to login with.`n" -ForegroundColor Yellow
                Write-Host -NoNewline "`e[1;37;44m[Login to Graph]`e[0m "
                Microsoft.Graph.Authentication\Connect-MgGraph @params | ForEach-Object {
                    if ($_ -is [string] -and $_ -cmatch ' ([A-Z0-9]{9}) ') {
                        $_ -replace $Matches[1], "`e[4m$($Matches[1])`e[24m"
                    }
                    else {
                        $_
                    }
                } | Out-Host
            }
            else {
                Write-Information 'Connecting to Microsoft Graph ...' -InformationAction Continue
                Microsoft.Graph.Authentication\Connect-MgGraph @params 1> $null
            }
        }
        catch {
            Write-Error "Microsoft Graph connection error: $($_.Exception.Message)" -ErrorAction Stop
            exit
        }
    }

    $MissingScopes = Get-MgMissingScope -Scopes $Scopes

    if ($MissingScopes) {
        if (
            $IsAzureAutomationJob -or
            (Get-MgContext).AuthType -ne 'Delegated'
        ) {
            Write-Error "Missing Microsoft Graph authorization scopes:`n`n$($MissingScopes -join "`n")" -ErrorAction Stop
            exit 1
        }

        if ($Scopes) { $params.Scopes = $Scopes }
        try {
            Write-Information 'Missing scopes, re-connecting to Microsoft Graph ...' -InformationAction Continue
            if ($params.UseDeviceCode) {
                Write-Host "Please select the account you want to login with.`n" -ForegroundColor Yellow
                Write-Host -NoNewline "`e[1;37;44m[Login to Graph]`e[0m "
                Microsoft.Graph.Authentication\Connect-MgGraph @params | ForEach-Object {
                    if ($_ -is [string] -and $_ -cmatch ' ([A-Z0-9]{9}) ') {
                        $_ -replace $Matches[1], "`e[4m$($Matches[1])`e[24m"
                    }
                    else {
                        $_
                    }
                } | Out-Host
            }
            else {
                Microsoft.Graph.Authentication\Connect-MgGraph @params 1> $null
            }
        }
        catch {
            Write-Error $_.Exception.Message -ErrorAction Stop
            exit
        }

        if (
            -Not (Get-MgContext) -or
            (Get-MgMissingScope -Scopes $Scopes).Count -gt 0
        ) {
            Write-Error "Missing Microsoft Graph authorization scopes:`n`n$($MissingScopes -join "`n")" -ErrorAction Stop
            exit
        }
    }

    if (
        [string]::IsNullOrEmpty($env:MG_PRINCIPAL_ID) -or
        [string]::IsNullOrEmpty($env:MG_PRINCIPAL_DISPLAYNAME)
    ) {
        try {
            $Context = Get-MgContext -ErrorAction Stop -Verbose:$false -Debug:$false

            if ($Context.AuthType -eq 'Delegated') {
                [Environment]::SetEnvironmentVariable('MG_PRINCIPAL_TYPE', 'Delegated', 'Process')
                Write-Verbose "[Connect-Auto_MgGraph]: - Getting user details for $($Context.Account) ..."
                $Principal = Invoke-MgGraphRequest -Uri "/v1.0/users/$($Context.Account)?`$select=id,displayName" -ErrorAction Stop -Verbose:$false -Debug:$false
            }
            else {
                [Environment]::SetEnvironmentVariable('MG_PRINCIPAL_TYPE', 'Application', 'Process')
                Write-Verbose "[Connect-Auto_MgGraph]: - Getting service principal details for $($Context.ClientId) ..."
                $Principal = (Invoke-MgGraphRequest -Uri "/v1.0/servicePrincipals?`$select=id,displayName&`$filter=appId eq '$($Context.ClientId)'" -ErrorAction Stop -Verbose:$false -Debug:$false).Value[0]
            }

            Write-Verbose "[Connect-Auto_MgGraph]: - Setting environment MG_PRINCIPAL_ID to '$($Principal.Id)' and MG_PRINCIPAL_DISPLAYNAME to '$($Principal.DisplayName)' ..."
            [Environment]::SetEnvironmentVariable('MG_PRINCIPAL_ID', $Principal.Id, 'Process')
            [Environment]::SetEnvironmentVariable('MG_PRINCIPAL_DISPLAYNAME', $Principal.DisplayName, 'Process')
        }
        catch {
            Write-Error $_.Exception.Message -ErrorAction Stop
            exit
        }
    }

    Write-Auto_FunctionEnd $MyInvocation -OnceOnly
}

New-Alias -Name 'Connect-Auto_Graph' -Value 'Connect-Auto_MgGraph' -Force
$ModuleMemberExport.Alias.Add('Connect-Auto_Graph')
