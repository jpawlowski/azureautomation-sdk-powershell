<#
.SYNOPSIS
    Write text in JSON format to output stream

.DESCRIPTION
    This script is used to write text in JSON format to the output stream. It takes an input object and converts it to JSON using the ConvertTo-Json cmdlet. The converted JSON is then written to the output stream.

.PARAMETER InputObject
    Specifies the object to be converted to JSON.

.PARAMETER ConvertToParam
    Specifies additional parameters to be passed to the ConvertTo-Json cmdlet.

.EXAMPLE
    PS> Write-Auto_JsonOutput -InputObject $data -ConvertToParam @{ Depth = 5; Compress = $false }
    This example converts the $data object to JSON with a depth of 5 and without compression, and writes it to the output stream.
#>

function Write-Auto_JsonOutput {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        $InputObject,

        [hashtable]$ConvertToParam
    )

    Write-Auto_FunctionBegin $MyInvocation -OnceOnly
    if ($null -eq $InputObject -or $InputObject.count -eq 0) { "{}"; exit }

    function Convert-DateTimeInObject {
        [CmdletBinding()]
        param (
            [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
            [psobject]$InputObject
        )

        process {
            function Convert-Object {
                param (
                    [psobject]$Obj
                )

                if ($Obj -is [System.Collections.IDictionary]) {
                    $keys = @($Obj.Keys)  # Create a copy of the keys to avoid modification issues
                    foreach ($key in $keys) {
                        $value = $Obj[$key]
                        if ($value -is [DateTime]) {
                            Write-Debug "Converting DateTime property '$key'"
                            $Obj[$key] = $value.ToString("o")
                        }
                        elseif ($value -is [PSObject] -or $value -is [System.Collections.IDictionary] -or ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string]))) {
                            Convert-Object -Obj $value
                        }
                    }
                }
                elseif ($Obj -is [PSObject]) {
                    $properties = @($Obj.PSObject.Properties)  # Create a copy of the properties to avoid modification issues
                    foreach ($property in $properties) {
                        if ($property.IsSettable) {
                            $value = $property.Value
                            if ($value -is [DateTime]) {
                                Write-Debug "Converting DateTime property '$($property.Name)'"
                                $Obj.$($property.Name) = $value.ToString("o")
                            }
                            elseif ($value -is [PSObject] -or $value -is [System.Collections.IDictionary] -or ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string]))) {
                                Convert-Object -Obj $value
                            }
                        }
                    }
                }
                elseif ($Obj -is [System.Collections.IEnumerable] -and -not ($Obj -is [string])) {
                    foreach ($item in $Obj) {
                        if ($item -is [PSObject] -or $item -is [System.Collections.IDictionary] -or ($item -is [System.Collections.IEnumerable] -and -not ($item -is [string]))) {
                            Convert-Object -Obj $item
                        }
                    }
                }
            }

            if ($InputObject -is [System.Collections.IEnumerable] -and -not ($InputObject -is [string])) {
                foreach ($item in $InputObject) {
                    if ($item -is [PSObject] -or $item -is [System.Collections.IDictionary] -or ($item -is [System.Collections.IEnumerable] -and -not ($item -is [string]))) {
                        Convert-Object -Obj $item
                    }
                }
            }
            elseif ($InputObject -is [PSObject] -or $InputObject -is [System.Collections.IDictionary] -or ($InputObject -is [System.Collections.IEnumerable] -and -not ($InputObject -is [string]))) {
                Convert-Object -Obj $InputObject
            }

            $InputObject
        }
    }

    try {
        $params = if ($ConvertToParam) { $ConvertToParam.Clone() } else { @{} }
        if ($null -eq $params.Compress) {
            if ($VerbosePreference -eq 'Continue' -or $DebugPreference -eq 'Continue') {
                $params.Compress = $false
            }
            else {
                $params.Compress = $true
            }
            Write-Verbose "Setting default compression to $($params.Compress)"
        }
        if ($null -eq $params.Depth) {
            Write-Verbose "Setting default depth to 5"
            $params.Depth = 5
        }

        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            Write-Output $($InputObject | Convert-DateTimeInObject | ConvertTo-Json @params)
        }
        else {
            Write-Output $($InputObject | ConvertTo-Json @params)
        }
    }
    catch {
        Throw $_.Exception.Message
    }

    Write-Auto_FunctionEnd $MyInvocation -OnceOnly
}
