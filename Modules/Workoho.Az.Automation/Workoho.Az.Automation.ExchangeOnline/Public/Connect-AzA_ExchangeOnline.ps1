<#
.SYNOPSIS
    Connects to Exchange Online and performs necessary actions.

.DESCRIPTION
    This script connects to Exchange Online and performs necessary actions based on the provided parameters. It checks if a connection already exists and if it is active. If the connection is not active or does not exist, it establishes a new connection.

.PARAMETER Organization
    Specifies the organization to connect to in Exchange Online.

.PARAMETER CommandName
    Specifies the Exchange Online commands to load. If not provided, all commands will be loaded.
    This parameter is useful when you want to load only specific commands to reduce memory consumption.

.EXAMPLE
    PS> Connect-AzA_ExchangeOnline -Organization "contoso.com" -CommandName "Get-Mailbox"
#>

function Connect-AzA_ExchangeOnline {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Required for device code authentication.')]
    [CmdletBinding()]
    Param(
        [Parameter(mandatory = $true)]
        [String]$Organization,

        [Array]$CommandName
    )

    Write-AzA_FunctionBegin $MyInvocation -OnceOnly

    #region [COMMON] ENVIRONMENT ---------------------------------------------------
    Import-AzA_Module @(
        @{ Name = 'ExchangeOnlineManagement'; MinimumVersion = '3.4'; MaximumVersion = '3.65535' }
    )
    #endregion ---------------------------------------------------------------------

    $params = @{
        Organization = $Organization
        ShowBanner   = $false
        ShowProgress = $false
        ErrorAction  = 'Stop'
        Verbose      = $false
        Debug        = $false
    }

    $Connection = Get-ConnectionInformation -ErrorAction Stop

    if (
        $Connection -and
        (
            ($Connection | Where-Object Organization -eq $params.Organization).State -ne 'Connected' -or
            ($Connection | Where-Object Organization -eq $params.Organization).tokenStatus -ne 'Active'
        )
    ) {
        $Connection | Where-Object Organization -eq $params.Organization | ForEach-Object {
            try {
                ExchangeOnlineManagement\Disconnect-ExchangeOnline `
                    -ConnectionId $_.ConnectionId `
                    -Confirm:$false `
                    -InformationAction SilentlyContinue `
                    -ErrorAction Stop 1> $null
            }
            catch {
                Write-Output '' 1> $null
            }
        }
        $Connection = $null
    }

    if (-Not ($Connection)) {
        if ($IsAzureAutomationJob) {
            $params.ManagedIdentity = $true
            $params.SkipLoadingCmdletHelp = $true
            $params.SkipLoadingFormatData = $true
        }
        elseif (
            $env:IS_DEV_CONTAINER -or
            $env:REMOTE_CONTAINERS -or
            $env:GITHUB_CODESPACE_TOKEN -or
            $env:AWS_CLOUD9_USER -or
            $IsNonUserInteractive
        ) {
            $params.Device = $true
        }

        if ($CommandName) {
            $params.CommandName = $CommandName
        }
        elseif ($IsAzureAutomationJob) {
            Write-Warning '[Connect-AzA_ExchangeOnline]: - Loading all Exchange Online commands. For improved memory consumption, consider adding -CommandName parameter with only required commands to be loaded.'
        }

        try {
            $OrigVerbosePreference = $Global:VerbosePreference
            $Global:VerbosePreference = 'SilentlyContinue'
            if ($params.Device) {
                Write-Host "Please select the account you want to login with.`n" -ForegroundColor Yellow
                Write-Host -NoNewline "`e[1;37;44m[Login to Exchange Online]`e[0m "
                ExchangeOnlineManagement\Connect-ExchangeOnline @params
            }
            else {
                Write-Information 'Connecting to Exchange Online ...' -InformationAction Continue
                ExchangeOnlineManagement\Connect-ExchangeOnline @params 1> $null
            }
        }
        catch {
            Write-Error $_.Exception.Message -ErrorAction Stop
            exit
        }
        finally {
            $Global:VerbosePreference = $OrigVerbosePreference
        }
    }

    Write-AzA_FunctionEnd $MyInvocation -OnceOnly
}
