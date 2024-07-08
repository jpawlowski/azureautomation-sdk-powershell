function Write-AzA_ScriptBegin {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        $TheirInvocation
    )

    if (
        -not [string]::IsNullOrEmpty($TheirInvocation.MyCommand.Name) -and
        $VerbosePreference -eq 'Continue' -or
        (
            $TheirInvocation.BoundParameters.ContainsKey('Verbose') -and
            $TheirInvocation.BoundParameters.Verbose -eq $true
        )
    ) {
        Write-Verbose "---START of SCRIPT $($TheirInvocation.MyCommand.Name) ---" -Verbose
    }
}
