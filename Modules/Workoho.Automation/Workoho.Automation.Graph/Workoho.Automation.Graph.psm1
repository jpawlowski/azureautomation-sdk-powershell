$Script:ModuleMemberExport = @{
    Function = [System.Collections.ArrayList] @()
    Cmdlet   = [System.Collections.ArrayList] @()
    Variable = [System.Collections.ArrayList] @()
    Alias    = [System.Collections.ArrayList] @()
}

Get-ChildItem -Path "$PSScriptRoot/Public" -Filter '*.ps1' -ErrorAction Stop | Where-Object { $_.Name -notlike '*.Tests.ps1' } | ForEach-Object {
    try {
        $ImportScriptFile = $_

        if ($_.BaseName -notmatch '^[A-Za-z]+-Auto_') {
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

Export-ModuleMember @ModuleMemberExport
