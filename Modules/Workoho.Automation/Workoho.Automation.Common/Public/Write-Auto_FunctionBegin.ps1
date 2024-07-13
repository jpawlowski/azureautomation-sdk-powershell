function Write-Auto_FunctionBegin {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        $TheirInvocation,

        [switch] $OnceOnly
    )

    if (-not $Script:ModuleFunctionHasRunBefore) {
        $Script:ModuleFunctionHasRunBefore = @{}
    }

    if ([string]::IsNullOrEmpty($TheirInvocation.MyCommand.ModuleName)) {
        $FunctionFullName = "$($TheirInvocation.InvocationName) ($(Get-ChildItem -Path $TheirInvocation.ScriptName -Name))"
    }
    else {
        $FunctionFullName = "$($TheirInvocation.MyCommand.ModuleName)\$($TheirInvocation.MyCommand.Name)"
    }

    if (
        (
            $OnceOnly -eq $false -or
            -not $Script:ModuleFunctionHasRunBefore.ContainsKey($FunctionFullName)
        ) -and
        (
            $VerbosePreference -eq 'Continue' -or
            (
                $TheirInvocation.BoundParameters.ContainsKey('Verbose') -and
                $TheirInvocation.BoundParameters.Verbose -eq $true
            )
        )
    ) {
        if ([string]::IsNullOrEmpty($TheirInvocation.MyCommand.ModuleName)) {
            Write-Verbose "---START of FUNCTION $FunctionFullName ---" -Verbose
        }
        else {
            Write-Verbose "---START of COMMAND $FunctionFullName, Version: $($TheirInvocation.MyCommand.Module.Version), Guid: $($TheirInvocation.MyCommand.Module.Guid) ---" -Verbose
        }
    }
}
