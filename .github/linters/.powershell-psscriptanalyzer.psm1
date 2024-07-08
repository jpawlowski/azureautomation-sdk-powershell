<#
.SYNOPSIS
    Custom rules for PSScriptAnalyzer that help to handle limitations in Azure Automation.
.DESCRIPTION
    This module contains custom rules for PSScriptAnalyzer that help to handle limitations in Azure Automation.
    The rules are based on the limitations in PowerShell 5.1 to ensure that the scripts are compatible with all versions of PowerShell.
#>

#Requires -Modules PSScriptAnalyzer

<#
.SYNOPSIS
    Measure-JoinPath
.DESCRIPTION
    Custom rule to check for usage of Join-Path
.EXAMPLE
    Measure-JoinPath -ScriptBlockAst $ScriptBlockAst
.INPUTS
    [System.Management.Automation.Language.ScriptBlockAst]
.OUTPUTS
    [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
#>
function Measure-JoinPath {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst] $ScriptBlockAst
    )

    process {
        $results = @()
        try {
            #region Define predicates to find ASTs.

            # Counts command elements.
            [ScriptBlock] $predicate1 = {
                param ([System.Management.Automation.Language.Ast] $Ast)
                [bool]$returnValue = $false
                if ($Ast -is [System.Management.Automation.Language.CommandAst]) {
                    if (
                        $Ast.CommandElements[0].Value -eq 'Join-Path' -and
                        $Ast.CommandElements.Count -gt 2
                    ) {
                        $returnValue = $true
                    }
                }
                return $returnValue
            }

            #endregion

            #region Finds ASTs that match the predicates.
            [System.Management.Automation.Language.Ast[]] $countAst = $ScriptBlockAst.FindAll($predicate1, $true)
            if (
                $countAst.Count -ne 0
            ) {
                $results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord] @{
                    Message  = 'Join-Path in PowerShell 5.1 can only handle two paths.'
                    Extent   = $countAst.Extent
                    RuleName = $PSCmdlet.MyInvocation.InvocationName
                    Severity = 'Warning'
                }
            }
            return $results
            #endregion
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

<#
.SYNOPSIS
    Measure-SplitPath
.DESCRIPTION
    Custom rule to check for usage of Split-Path
.EXAMPLE
    Measure-SplitPath -ScriptBlockAst $ScriptBlockAst
.INPUTS
    [System.Management.Automation.Language.ScriptBlockAst]
.OUTPUTS
    [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
#>
function Measure-SplitPath {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst] $ScriptBlockAst
    )

    process {
        $results = @()
        try {
            #region Define predicates to find ASTs.

            # Counts command elements.
            [ScriptBlock] $predicate1 = {
                param ([System.Management.Automation.Language.Ast] $Ast)
                [bool]$returnValue = $false
                if ($Ast -is [System.Management.Automation.Language.CommandAst]) {
                    if (
                        $Ast.CommandElements[0].Value -eq 'Split-Path' -and
                        $Ast.CommandElements.Value -contains '-LeafBase'
                    ) {
                        $returnValue = $true
                    }
                }
                return $returnValue
            }

            #endregion

            #region Finds ASTs that match the predicates.
            [System.Management.Automation.Language.Ast[]] $countAst = $ScriptBlockAst.FindAll($predicate1, $true)
            if (
                $countAst.Count -ne 0
            ) {
                $results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord] @{
                    Message  = 'Split-Path in PowerShell 5.1 does not support the -LeafBase parameter.'
                    Extent   = $countAst.Extent
                    RuleName = $PSCmdlet.MyInvocation.InvocationName
                    Severity = 'Warning'
                }
            }
            return $results
            #endregion
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

<#
.SYNOPSIS
    Measure-GetChildItem
.DESCRIPTION
    Custom rule to check for usage of Get-ChildItem
.EXAMPLE
    Measure-GetChildItem -ScriptBlockAst $ScriptBlockAst
.INPUTS
    [System.Management.Automation.Language.ScriptBlockAst]
.OUTPUTS
    [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
#>
function Measure-GetChildItem {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst] $ScriptBlockAst
    )

    process {
        $results = @()
        try {
            #region Define predicates to find ASTs.

            # Counts command elements.
            [ScriptBlock] $predicate1 = {
                param ([System.Management.Automation.Language.Ast] $Ast)
                [bool]$returnValue = $false
                if ($Ast -is [System.Management.Automation.Language.CommandAst]) {
                    if (
                        $Ast.CommandElements[0].Value -eq 'Get-ChildItem' -and
                        $Ast.CommandElements.Value -contains '-Depth'
                    ) {
                        $returnValue = $true
                    }
                }
                return $returnValue
            }

            #endregion

            #region Finds ASTs that match the predicates.
            [System.Management.Automation.Language.Ast[]] $countAst = $ScriptBlockAst.FindAll($predicate1, $true)
            if (
                $countAst.Count -ne 0
            ) {
                $results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord] @{
                    Message  = 'Get-ChildItem in PowerShell 5.1 does not support the -Depth parameter.'
                    Extent   = $countAst.Extent
                    RuleName = $PSCmdlet.MyInvocation.InvocationName
                    Severity = 'Warning'
                }
            }
            return $results
            #endregion
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

<#
.SYNOPSIS
    Measure-ConvertToJson
.DESCRIPTION
    Custom rule to check for usage of ConvertTo-Json
.EXAMPLE
    Measure-ConvertToJson -ScriptBlockAst $ScriptBlockAst
.INPUTS
    [System.Management.Automation.Language.ScriptBlockAst]
.OUTPUTS
    [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
#>
function Measure-ConvertToJson {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst] $ScriptBlockAst
    )

    process {
        $results = @()
        try {
            #region Define predicates to find ASTs.

            # Counts command elements.
            [ScriptBlock] $predicate1 = {
                param ([System.Management.Automation.Language.Ast] $Ast)
                [bool]$returnValue = $false
                if ($Ast -is [System.Management.Automation.Language.CommandAst]) {
                    if (
                        $Ast.CommandElements[0].Value -eq 'ConvertTo-Json' -and
                        $Ast.CommandElements.Value -contains '-AsHashtable'
                    ) {
                        $returnValue = $true
                    }
                }
                return $returnValue
            }

            #endregion

            #region Finds ASTs that match the predicates.
            [System.Management.Automation.Language.Ast[]] $countAst = $ScriptBlockAst.FindAll($predicate1, $true)
            if (
                $countAst.Count -ne 0
            ) {
                $results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord] @{
                    Message  = 'ConvertTo-Json in PowerShell 5.1 does not support the -AsHashtable parameter.'
                    Extent   = $countAst.Extent
                    RuleName = $PSCmdlet.MyInvocation.InvocationName
                    Severity = 'Warning'
                }
            }
            return $results
            #endregion
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

<#
.SYNOPSIS
    Measure-InvokeRestMethod
.DESCRIPTION
    Custom rule to check for usage of Invoke-RestMethod
.EXAMPLE
    Measure-InvokeRestMethod -ScriptBlockAst $ScriptBlockAst
.INPUTS
    [System.Management.Automation.Language.ScriptBlockAst]
.OUTPUTS
    [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
#>
function Measure-InvokeRestMethod {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst] $ScriptBlockAst
    )

    process {
        $results = @()
        try {
            #region Define predicates to find ASTs.

            # Counts command elements.
            [ScriptBlock] $predicate1 = {
                param ([System.Management.Automation.Language.Ast] $Ast)
                [bool]$returnValue = $false
                if ($Ast -is [System.Management.Automation.Language.CommandAst]) {
                    if (
                        $Ast.CommandElements[0].Value -eq 'Invoke-RestMethod' -and
                        $Ast.CommandElements.Value -contains '-AsHashtable'
                    ) {
                        $returnValue = $true
                    }
                }
                return $returnValue
            }

            [ScriptBlock] $predicate2 = {
                param ([System.Management.Automation.Language.Ast] $Ast)
                [bool]$returnValue = $false
                if ($Ast -is [System.Management.Automation.Language.CommandAst]) {
                    if (
                        $Ast.CommandElements[0].Value -eq 'Invoke-RestMethod' -and
                        $Ast.CommandElements.Value -notcontains '-UseBasicParsing'
                    ) {
                        $returnValue = $true
                    }
                }
                return $returnValue
            }

            #endregion

            #region Finds ASTs that match the predicates.
            [System.Management.Automation.Language.Ast[]] $countAst = $ScriptBlockAst.FindAll($predicate1, $true)
            [System.Management.Automation.Language.Ast[]] $countAst2 = $ScriptBlockAst.FindAll($predicate2, $true)
            if (
                $countAst.Count -ne 0
            ) {
                $results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord] @{
                    Message  = 'Invoke-RestMethod in PowerShell 5.1 does not support the -SkipCertificateCheck parameter.'
                    Extent   = $countAst.Extent
                    RuleName = $PSCmdlet.MyInvocation.InvocationName
                    Severity = 'Warning'
                }
            }
            if (
                $countAst2.Count -ne 0
            ) {
                $results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord] @{
                    Message  = 'Invoke-RestMethod in PowerShell 5.1 should be used with the -UseBasicParsing parameter to avoid dependency on Internet Explorer.'
                    Extent   = $countAst2.Extent
                    RuleName = $PSCmdlet.MyInvocation.InvocationName
                    Severity = 'Warning'
                }
            }
            return $results
            #endregion
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

<#
.SYNOPSIS
    Measure-InvokeWebRequest
.DESCRIPTION
    Custom rule to check for usage of Invoke-WebRequest
.EXAMPLE
    Measure-InvokeWebRequest -ScriptBlockAst $ScriptBlockAst
.INPUTS
    [System.Management.Automation.Language.ScriptBlockAst]
.OUTPUTS
    [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
#>
function Measure-InvokeWebRequest {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst] $ScriptBlockAst
    )

    process {
        $results = @()
        try {
            #region Define predicates to find ASTs.

            # Counts command elements.
            [ScriptBlock] $predicate1 = {
                param ([System.Management.Automation.Language.Ast] $Ast)
                [bool]$returnValue = $false
                if ($Ast -is [System.Management.Automation.Language.CommandAst]) {
                    if (
                        $Ast.CommandElements[0].Value -eq 'Invoke-WebRequest' -and
                        $Ast.CommandElements.Value -contains '-AsHashtable'
                    ) {
                        $returnValue = $true
                    }
                }
                return $returnValue
            }

            [ScriptBlock] $predicate2 = {
                param ([System.Management.Automation.Language.Ast] $Ast)
                [bool]$returnValue = $false
                if ($Ast -is [System.Management.Automation.Language.CommandAst]) {
                    if (
                        $Ast.CommandElements[0].Value -eq 'Invoke-WebRequest' -and
                        $Ast.CommandElements.Value -notcontains '-UseBasicParsing'
                    ) {
                        $returnValue = $true
                    }
                }
                return $returnValue
            }

            #endregion

            #region Finds ASTs that match the predicates.
            [System.Management.Automation.Language.Ast[]] $countAst = $ScriptBlockAst.FindAll($predicate1, $true)
            [System.Management.Automation.Language.Ast[]] $countAst2 = $ScriptBlockAst.FindAll($predicate2, $true)
            if (
                $countAst.Count -ne 0
            ) {
                $results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord] @{
                    Message  = 'Invoke-WebRequest in PowerShell 5.1 does not support the -SkipCertificateCheck parameter.'
                    Extent   = $countAst.Extent
                    RuleName = $PSCmdlet.MyInvocation.InvocationName
                    Severity = 'Warning'
                }
            }
            if (
                $countAst2.Count -ne 0
            ) {
                $results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord] @{
                    Message  = 'Invoke-WebRequest in PowerShell 5.1 should be used with the -UseBasicParsing parameter to avoid dependency on Internet Explorer.'
                    Extent   = $countAst2.Extent
                    RuleName = $PSCmdlet.MyInvocation.InvocationName
                    Severity = 'Warning'
                }
            }
            return $results
            #endregion
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

<#
.SYNOPSIS
    Measure-NewObject
.DESCRIPTION
    Custom rule to check for usage of New-Object
.EXAMPLE
    Measure-NewObject -ScriptBlockAst $ScriptBlockAst
.INPUTS
    [System.Management.Automation.Language.ScriptBlockAst]
.OUTPUTS
    [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
#>
function Measure-NewObject {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst] $ScriptBlockAst
    )

    process {
        $results = @()
        try {
            #region Define predicates to find ASTs.

            # Counts command elements.
            [ScriptBlock] $predicate1 = {
                param ([System.Management.Automation.Language.Ast] $Ast)
                [bool]$returnValue = $false
                if ($Ast -is [System.Management.Automation.Language.CommandAst]) {
                    if (
                        $Ast.CommandElements[0].Value -eq 'New-Object' -and
                        $Ast.CommandElements.Value -contains '-Property'
                    ) {
                        $propertyArgument = $Ast.CommandElements[$Ast.CommandElements.IndexOf('-Property') + 1]
                        if (
                            $propertyArgument.Type -is [System.Management.Automation.Language.HashtableAst] -or
                            $propertyArgument.Type -is [System.Management.Automation.Language.PSObjectAst]
                        ) {
                            # Check if the hashtable or psobject contains properties with values of type psobject
                            foreach ($pair in $propertyArgument.Pairs) {
                                if ($pair.Value.Type -is [System.Management.Automation.Language.PSObjectAst]) {
                                    $returnValue = $true
                                    break
                                }
                            }
                        }
                    }
                }
                return $returnValue
            }

            #endregion

            #region Finds ASTs that match the predicates.
            [System.Management.Automation.Language.Ast[]] $countAst = $ScriptBlockAst.FindAll($predicate1, $true)
            if (
                $countAst.Count -ne 0
            ) {
                $results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord] @{
                    Message  = 'New-Object in PowerShell 5.1 does not support the -Property parameter with a hashtable or psobject that contains properties with values of type psobject.'
                    Extent   = $countAst.Extent
                    RuleName = $PSCmdlet.MyInvocation.InvocationName
                    Severity = 'Warning'
                }
            }
            return $results
            #endregion
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

# Export the function as a rule for PSScriptAnalyzer
Export-ModuleMember -Function Measure-JoinPath
Export-ModuleMember -Function Measure-SplitPath
Export-ModuleMember -Function Measure-GetChildItem
Export-ModuleMember -Function Measure-ConvertToJson
Export-ModuleMember -Function Measure-InvokeRestMethod
Export-ModuleMember -Function Measure-InvokeWebRequest
Export-ModuleMember -Function Measure-NewObject
