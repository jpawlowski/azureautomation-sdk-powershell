<#
.SYNOPSIS
    Imports modules silently

.DESCRIPTION
    This script imports PowerShell modules silently. It is designed to be used in Azure Automation runbooks or when running locally. The script supports importing multiple modules and allows setting the AutoloadingPreference for PowerShell modules.
    When running in Azure Automation, the script enforces manual Import-Module to ensure module dependencies are resolved correctly.

.PARAMETER Modules
    Specifies the modules to import. This parameter accepts an array of module objects. Each module object should have a 'Name' property that specifies the name of the module to import. Optional modules can be specified by adding an 'Optional' property set to $true.

.EXAMPLE
    PS> Import-AzA_Module -Name @('Module1', 'Module2')

    Imports 'Module1' and 'Module2' silently.
#>

function Import-AzA_Module {
    [CmdletBinding()]
    Param(
        [Parameter(mandatory = $true)]
        [AllowEmptyCollection()]
        [array]$Name,

        [string]$AutoloadingPreference
    )

    # Works only when running locally
    $OrigVerbosePreference = $VerbosePreference
    $VerbosePreference = 'SilentlyContinue'

    # Works only when running in Azure Automation sandbox
    $OrigGlobalVerbosePreference = $Global:VerbosePreference
    $Global:VerbosePreference = 'SilentlyContinue'

    try {
        if (-Not (Get-Module -Name PowerShellGet)) {
            $params = @{
                Name        = 'PowerShellGet'
                Global      = $true
                Verbose     = $false
                Debug       = $false
                ErrorAction = 'Stop'
            }
            Import-Module @params 1> $null
        }
    }
    catch {
        Throw $_
    }
    finally {
        $VerbosePreference = $OrigVerbosePreference
        $Global:VerbosePreference = $OrigGlobalVerbosePreference
    }

    Write-AzA_FunctionBegin $MyInvocation -OnceOnly

    $LoadedModules = (Get-Module | & { process { $_.Name } })
    $Missing = [System.Collections.ArrayList]::new()

    @($Name) | ForEach-Object {
        if (
            $null -eq $_ -or
            (
                $_ -isnot [string] -and
                $_ -isnot [hashtable]
            ) -or
            (
                $_ -is [string] -and
                (
                    [string]::IsNullOrEmpty($_) -or
                    $LoadedModules -contains $_
                )
            ) -or
            (
                $_ -is [hashtable] -and
                (
                    [string]::IsNullOrEmpty($_.Name) -or
                    $LoadedModules -contains $_.Name
                )
            )
        ) {
            return
        }

        $Module = if ($_ -is [string]) { @{ Name = $_ } } else { $_ }
        $IsOptional = $_.Optional -eq $true
        if ($null -ne $Module.Optional) { $Module.Remove('Optional') }
        $Module.Debug = $false
        $Module.Verbose = $false
        $Module.InformationAction = 'SilentlyContinue'
        $Module.WarningAction = 'SilentlyContinue'
        $Module.ErrorAction = 'Stop'
        $Module.DisableNameChecking = $true
        $Module.Global = $true

        try {
            Write-Debug "[Import-AzA_Module]: - Silently importing module $($Module.Name)"

            $VerbosePreference = 'SilentlyContinue'
            $Global:VerbosePreference = 'SilentlyContinue'

            Import-Module @Module 1> $null

            $VerbosePreference = $OrigVerbosePreference
            $Global:VerbosePreference = $OrigGlobalVerbosePreference
            Write-Verbose "--IMPORT of MODULE $($Module.Name), $((Get-Module -Name $($Module.Name) | Select-Object -Property Version, Guid | ForEach-Object { $_.PSObject.Properties | ForEach-Object { $_.Name + ': ' + $_.Value } }) -join ', ') ---"
        }
        catch {
            if ($IsOptional) {
                Write-Warning "[Import-AzA_Module]: - Optional module could not be loaded: $(Module.Name)"
            }
            else {
                $Module.Remove('Debug')
                $Module.Remove('Verbose')
                $Module.Remove('InformationAction')
                $Module.Remove('WarningAction')
                $Module.Remove('ErrorAction')
                $Module.Remove('DisableNameChecking')
                $Module.Remove('Global')
                $Module.ErrorDetails = $_
                [void] $Missing.Add($Module)
            }
        }
    }

    $VerbosePreference = $OrigVerbosePreference
    $Global:VerbosePreference = $OrigGlobalVerbosePreference

    If ($Missing.Count -gt 0) {
        Throw "Modules could not be loaded: $( $(ForEach ($item in $Missing | Sort-Object -Property Name) { ($item.Keys | Sort-Object @{Expression={$_ -eq "Name" -or $_ -eq "RequiredVersion"}; Descending=$true} | ForEach-Object { "${_}: $($item[$_])" }) -join '; ' }) -join ' | ' )"
    }

    Remove-Variable -Name OrigVerbosePreference, Missing, LoadedModules, Modules, Module -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -Verbose:$false -Debug:$false -Confirm:$false -WhatIf:$false

    Write-AzA_FunctionEnd $MyInvocation -OnceOnly
}
