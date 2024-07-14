if ($PSVersionTable.PSVersion -lt 7.2) {
    Throw 'Workoho.Automation requires PowerShell version 7.2 or higher.'
    exit 1
}
