if ($PSVersionTable.PSVersion -lt 7.2) {
    Throw 'Workoho.Az.Automation requires PowerShell version 7.2 or higher.'
    exit 1
}
