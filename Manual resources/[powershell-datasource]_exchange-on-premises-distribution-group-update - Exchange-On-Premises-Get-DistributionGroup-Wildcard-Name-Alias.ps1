# Variables configured in form
$searchValue = $datasource.searchValue
if ($searchValue -eq "*") {
    $filter = "*"
}
else {
    $filter = "Alias -like '*$searchValue*' -or Name -like '*$searchValue*' -or SamAccountName -like '*$searchValue*' -or PrimarySmtpAddress -like '*$searchValue*'"
}

# Global variables
# Outcommented as these are set from Global Variables
# $ExchangeConnectionUri = ""
# $ExchangeAdminUsername = ""
# $ExchangeAdminPassword = ""

# Fixed values
# Properties to select - Select only needed properties to limit memory usage and speed up processing
$propertiesToSelect = @(
    "Guid"
    , "DisplayName"
    , "Name"
    , "Alias"
    , "PrimarySmtpAddress"
    , "EmailAddresses"
    , "DistinguishedName"    
)

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

# Set debug logging
$VerbosePreference = "SilentlyContinue"
$InformationPreference = "Continue"
$WarningPreference = "Continue"

#region functions
#endregion functions

try {
    # Create credentials
    $actionMessage = "creating credentials object"
    
    $securePassword = ConvertTo-SecureString -String $ExchangeAdminPassword -AsPlainText -Force
    $credential = [System.Management.Automation.PSCredential]::new($ExchangeAdminUsername, $securePassword)

    # Connect to Exchange On-Premises
    # Docs: https://learn.microsoft.com/en-us/powershell/exchange/connect-to-exchange-servers-using-remote-powershell
    $actionMessage = "connecting to Exchange On-Premises using URI [$ExchangeConnectionUri]"

    $sessionOptionParams = @{
        SkipCACheck         = $false
        SkipCNCheck         = $false
        SkipRevocationCheck = $false
    }

    $sessionOption = New-PSSessionOption @sessionOptionParams

    $sessionParams = @{
        Authentication    = 'Default'
        ConfigurationName = 'Microsoft.Exchange'
        ConnectionUri     = $ExchangeConnectionUri
        Credential        = $credential
        SessionOption     = $sessionOption
        ErrorAction       = "Stop"
    }

    $exchangeSession = New-PSSession @sessionParams
    $null = Import-PSSession -Session $exchangeSession -DisableNameChecking -AllowClobber -CommandName "Get-DistributionGroup" -ErrorAction Stop

    # Get Distribution Groups
    # Docs: https://learn.microsoft.com/en-us/powershell/module/exchangepowershell/get-distributiongroup
    $actionMessage = "querying distribution groups that match filter [$($filter)]"

    $getDistributionGroupParams = @{        
        Filter = $filter           
        ErrorAction = 'Stop'
    }
   
    $distributionGroups = Get-DistributionGroup @getDistributionGroupParams | Select-Object -Property $propertiesToSelect   
    Write-Information "Queried distribution groups that match filter [$($filter)]. Result count: $(($distributionGroups | Measure-Object).Count)"

    # Sort and send results to HelloID
    $actionMessage = "sending results to HelloID"
    $distributionGroups | Add-Member -MemberType NoteProperty -Name "mailPrefix" -Value $null -Force
    $distributionGroups | Add-Member -MemberType NoteProperty -Name "mailDomain" -Value $null -Force
    $distributionGroups | Sort-Object -Property DisplayName | ForEach-Object {
        # Set mailDomain and mailPrefix properties
        $_.mailPrefix = $_.PrimarySmtpAddress.split('@')[0]
        $_.mailDomain = $_.PrimarySmtpAddress.split('@')[1]
        Write-Output $_
    }  
}
catch {
    $ex = $PSItem
    if (-not [string]::IsNullOrEmpty($ex.Exception.Message)) {
        $warningMessage = "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
        $auditMessage = "Error $($actionMessage). Error: $($ex.Exception.Message)"
    }
    else {
        $warningMessage = "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception)"
        $auditMessage = "Error $($actionMessage). Error: $($ex.Exception)"
    }
    Write-Warning $warningMessage
    Write-Error $auditMessage
    # exit # use when using multiple try/catch and the script must stop
}
finally {
    # Disconnect from Exchange
    # Docs: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/remove-pssession
    if ($null -ne $exchangeSession) {
        try {
            $deleteExchangeSessionSplatParams = @{
                Session     = $exchangeSession
                Confirm     = $false
                ErrorAction = "Stop"
            }
            $null = Remove-PSSession @deleteExchangeSessionSplatParams
        }
        catch {
            Write-Warning "Failed to disconnect from Exchange using URI [$ExchangeConnectionUri]. Error: $($_.Exception.Message)"
        }
    }
}
