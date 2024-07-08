[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'GlobalVars required to restore ConfirmPreference after module was removed.')]
param()

# Remove pre-import script module from memory
Remove-Module -Force -Name Initialize-AzA_RuntimeEnvironmentBeforeImport -ErrorAction Ignore

$Script:ModuleMemberExport = @{
    Function = [System.Collections.ArrayList] @()
    Cmdlet   = [System.Collections.ArrayList] @()
    Variable = [System.Collections.ArrayList] @()
    Alias    = [System.Collections.ArrayList] @()
}

Get-ChildItem -Path "$PSScriptRoot/Private", "$PSScriptRoot/Public" -Filter '*.ps1' -ErrorAction Stop | Where-Object { $_.Name -notlike '*.Tests.ps1' } | ForEach-Object {
    try {
        $ImportScriptFile = $_

        if ($_.BaseName -notmatch '^[A-Za-z]+-AzA_') {
            Throw "File name does not match the expected pattern."
        }

        . $_.FullName

        if (
            @(
                (
                    Get-ChildItem -Path Function: | Where-Object Source -eq $MyInvocation.MyCommand.ScriptBlock.Module
                ).Name
            ) -inotcontains $_.BaseName
        ) {
            Throw "File does not contain the expected function named '$($_.BaseName)'"
        }

        if ($_.Directory.Name -eq 'Public') {
            [void] $Script:ModuleMemberExport.Function.Add($_.BaseName)
        }
    }
    catch {
        Write-Error "Failed to import script $(Join-Path $ImportScriptFile.Directory.Name $ImportScriptFile.Name). Error: $_"
    }
    finally {
        Remove-Variable ImportScriptFile -ErrorAction Ignore
    }
}

Initialize-AzA_RuntimeEnvironment

Export-ModuleMember @ModuleMemberExport

# Clean up the environment after the module is removed
$ExecutionContext.SessionState.Module.OnRemove = {
    if (Get-Module -Name Az.*) {
        $null = Disconnect-AzAccount -Confirm:$false -WhatIf:$false -ErrorAction Ignore
        $null = Remove-Module -Force -Name Az.* -Confirm:$false -WhatIf:$false -ErrorAction Ignore
    }

    if (Get-Module -Name Microsoft.Graph.*) {
        $null = Disconnect-MgGraph -ErrorAction Ignore
        $null = Remove-Module -Force -Name Microsoft.Graph.* -Confirm:$false -WhatIf:$false -ErrorAction Ignore
    }

    if (Get-Module -Name ExchangeOnlineManagement) {
        $null = Disconnect-ExchangeOnline -Confirm:$false -WhatIf:$false -ErrorAction Ignore
        $null = Remove-Module -Force -Name ExchangeOnlineManagement -Confirm:$false -WhatIf:$false -ErrorAction Ignore
    }

    if (Get-Module -Name MicrosoftTeams) {
        $null = Disconnect-MicrosoftTeams -Confirm:$false -WhatIf:$false -ErrorAction Ignore
        $null = Remove-Module -Force -Name MicrosoftTeams -Confirm:$false -WhatIf:$false -ErrorAction Ignore
    }

    if (Get-Module -Name PnP.PowerShell) {
        $null = Disconnect-PnPOnline -ErrorAction Ignore
        $null = Remove-Module -Force -Name PnP.PowerShell -Confirm:$false -WhatIf:$false -ErrorAction Ignore
    }

    if ($null -ne $Global:PreAzAModule_ConfirmPreference) {
        Write-Verbose 'Restoring $ConfirmPreference to its original value.' -Verbose
        $Global:ConfirmPreference = $Global:PreAzAModule_ConfirmPreference
        Remove-Variable -Force -Scope Global -Name PreAzAModuleConfirmPreference -ErrorAction Ignore
    }
}
