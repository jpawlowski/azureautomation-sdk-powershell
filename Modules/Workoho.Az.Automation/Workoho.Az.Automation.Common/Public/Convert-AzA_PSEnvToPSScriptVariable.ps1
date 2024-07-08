<#
.SYNOPSIS
    This script converts PowerShell environment variables to script variables, based on a configuration file.

.DESCRIPTION
    This script takes an array of variables and converts them to script variables. It provides options to respect script parameters with higher priority and set default values, based on a configuration file.
    When used in conjunction with the Import-AzA_AzAutomationVariableToPSEnv function, it allows for the import of Azure Automation variables to PowerShell environment variables and then to script variables.

    The advantage is that during local development, the script can be tested with environment variables, and in Azure Automation, the script can use Azure Automation variables instead.
    This is in particular useful for configuration options or sensitive information, such as passwords, which should not be stored in the script itself.

.PARAMETER Variable
    An array of variables to convert to script variables.

.PARAMETER ScriptParameterOnly
    A boolean value indicating whether to process only script parameters.

.EXAMPLE
    PS> Convert-AzA_PSEnvToPSScriptVariable -Variable MyVariable -ScriptParameterOnly $true

    This example converts the environment variable 'MyVariable' to a script variable, respecting script parameters only.
#>

function Convert-AzA_PSEnvToPSScriptVariable {
    [CmdletBinding()]
    Param(
        [Parameter(mandatory = $true)]
        [AllowEmptyCollection()]
        [array]$Variable,

        [switch] $ScriptParameterOnly
    )

    Write-AzA_FunctionBegin $MyInvocation

    @($Variable) | ForEach-Object {
        # Script parameters be of type array/collection and be processed during a loop,
        # and therefore updated multiple times
        if (
            (
                    ($ScriptParameterOnly -eq $true) -and ($null -eq $_.respectScriptParameter)
            ) -or
            (
                    ($ScriptParameterOnly -eq $false) -and ($null -ne $_.respectScriptParameter)
            )
        ) { return }

        if ($null -eq $_.mapToVariable) {
            Write-Warning "[COMMON]: - [$($_.sourceName) --> `$Script:???] Missing mapToVariable property in configuration."
            return
        }

        $params = @{
            Name    = $_.mapToVariable
            Scope   = 2
            Force   = $true
            Verbose = $false
            Debug   = $false
            Confirm = $false
            WhatIf  = $false
        }

        if (-Not $_.respectScriptParameter) { $params.Option = 'Constant' }

        if (
            $_.respectScriptParameter -and
            $null -ne $(Get-Variable -Name $_.respectScriptParameter -Scope $params.Scope -ValueOnly -ErrorAction SilentlyContinue)
        ) {
            $params.Value = Get-Variable -Name $_.respectScriptParameter -Scope $params.Scope -ValueOnly
            Write-Verbose "[COMMON]: - [$($_.sourceName) --> `$Script:$($params.Name)] Using value from script parameter $($_.respectScriptParameter)"
        }
        elseif ($null -ne [Environment]::GetEnvironmentVariable($_.sourceName)) {
            $params.Value = (Get-ChildItem -Path "env:$($_.sourceName)").Value
            Write-Verbose "[COMMON]: - [$($_.sourceName) --> `$Script:$($params.Name)] Using value from `$env:$($_.sourceName)"
        }
        elseif ($_.ContainsKey('defaultValue')) {
            $params.Value = $_.defaultValue
            Write-Verbose "[COMMON]: - [$($_.sourceName) --> `$Script:$($params.Name)] `$env:$($_.sourceName) not found, using built-in default value"
        }
        else {
            Write-Error "[COMMON]: - [$($_.sourceName) --> `$Script:$($params.Name)] Missing default value in configuration."
            return
        }

        if (
            $null -ne $params.Value -and
            $params.Value.GetType().Name -eq 'String' -and
            (
                $params.Value -eq '""' -or
                $params.Value -eq "''"
            )
        ) {
            Write-Verbose "[COMMON]: - [$($_.sourceName) --> `$Script:$($params.Name)] Value converted to empty string."
            $params.Value = [string]''
        }

        if (
            -Not $_.Regex -and
            $null -ne $params.Value -and
            $params.Value.GetType().Name -eq 'String'
        ) {
            if ($params.Value -eq 'True') {
                $params.Value = $true
                Write-Verbose "[COMMON]: - [$($_.sourceName) --> `$Script:$($params.Name)] Value converted to boolean True"
            }
            elseif ($params.Value -eq 'False') {
                $params.Value = $false
                Write-Verbose "[COMMON]: - [$($_.sourceName) --> `$Script:$($params.Name)] Value converted to boolean False"
            }
            elseif ($_.ContainsKey('defaultValue')) {
                $params.Value = $_.defaultValue
                Write-Warning "[COMMON]: - [$($_.sourceName) --> `$Script:$($params.Name)] Value does not seem to be a boolean, using built-in default value"
            }
            else {
                Write-Error "[COMMON]: - [$($_.sourceName) --> `$Script:$($params.Name)] Value does not seem to be a boolean, and no default value was found in configuration."
                return
            }
        }

        if (
            $_.Regex -and
            (-Not [String]::IsNullOrEmpty($params.Value)) -and
            ($params.Value -notmatch $_.Regex)
        ) {
            $params.Value = $null
            if ($_.ContainsKey('defaultValue')) {
                $params.Value = $_.defaultValue
                Write-Warning "[COMMON]: - [$($_.sourceName) --> `$Script:$($params.Name)] Value does not match '$($_.Regex)', using built-in default value"
            }
            else {
                Write-Error "[COMMON]: - [$($_.sourceName) --> `$Script:$($params.Name)] Value does not match '$($_.Regex)', and no default value was found in configuration."
                return
            }
        }
        New-Variable @params
    }

    Write-AzA_FunctionEnd $MyInvocation
}
