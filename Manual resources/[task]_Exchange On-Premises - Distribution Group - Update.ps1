# variables configured in form:
$distributionGroup = $form.gridGroup
$distributionGroupDisplayName = $form.displayName
$distributionGroupAlias = $form.alias
$distributionGroupMailPrefix = $form.mailPrefix
$distributionGroupMailDomain = $form.mailDomain.id
$blnSetAsPrimaryEmail = if ([string]::IsNullOrWhiteSpace($form.blnSetAsPrimaryEmail)) { $false } else { [System.Convert]::ToBoolean($form.blnSetAsPrimaryEmail) }
# Build proxy address with appropriate prefix based on whether it should be primary
if ($blnSetAsPrimaryEmail) {
    $distributionGroupProxyAddress = "SMTP:$($distributionGroupMailPrefix)@$($distributionGroupMailDomain)"
}
else {
    $distributionGroupProxyAddress = "smtp:$($distributionGroupMailPrefix)@$($distributionGroupMailDomain)"
}

# Global variables
# Outcommented as these are set from Global Variables
# $ExchangeConnectionUri = ""
# $ExchangeAdminUsername = ""
# $ExchangeAdminPassword = ""

# PowerShell commands to import
$commands = @("Set-DistributionGroup")
#endregion init

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

# Set debug logging
$VerbosePreference = "SilentlyContinue"
$InformationPreference = "Continue"
$WarningPreference = "Continue"

#region functions
#endregion functions

#region Import module & connect
try {    
     # Create credentials
    $actionMessage = "creating credentials object"
    
    $securePassword = ConvertTo-SecureString -String $ExchangeAdminPassword -AsPlainText -Force
    $credential = [System.Management.Automation.PSCredential]::new($ExchangeAdminUsername, $securePassword)
    
    Write-Verbose "Created credentials for user [$ExchangeAdminUsername]"

    # Connect to Exchange On-Premises
    # Docs: https://learn.microsoft.com/en-us/powershell/exchange/connect-to-exchange-servers-using-remote-powershell
    $actionMessage = "connecting to Exchange On-Premises"

    $sessionOptionParams = @{
        SkipCACheck         = $false
        SkipCNCheck         = $false
        SkipRevocationCheck = $false
    }

    $sessionOption = New-PSSessionOption @sessionOptionParams

    $sessionParams = @{
        Authentication    = 'Default'
        ConfigurationName = 'Microsoft.Exchange'
        Credential        = $credential
        ConnectionUri     = $ExchangeConnectionUri
        SessionOption     = $sessionOption
        ErrorAction       = "Stop"
    }

    $exchangeSession = New-PSSession @sessionParams
    $null = Import-PSSession -Session $exchangeSession -DisableNameChecking -AllowClobber -CommandName $commands -ErrorAction Stop

    # Send initial audit log
    $Log = @{
        Action            = "DeleteResource" # optional. ENUM (undefined = default) 
        System            = "Exchange On-Premises" # optional (free format text) 
        Message           = "Successfully connected to Exchange using URI [$ExchangeConnectionUri]" # required (free format text) 
        IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
        TargetDisplayName = $ExchangeConnectionUri # optional (free format text) 
        TargetIdentifier  = $([string]$exchangeSession.InstanceId) # optional (free format text) 
    }
    Write-Information -Tags "Audit" -MessageData $log

    # Get current email addresses and prepare new email address list, while keeping existing proxy addresses (except the current address if already present)
    $currentAddresses = $distributionGroup.EmailAddresses
    $proxyAddresses = @()
    
    # Extract the email address without prefix for comparison
    $emailAddressOnly = $distributionGroupProxyAddress -replace '^(smtp|SMTP):', ''
    
    foreach ($address in $currentAddresses) {
        # If setting as primary, convert any existing primary SMTP to secondary
        if ($blnSetAsPrimaryEmail -and $address.StartsWith('SMTP:')) {
            $address = $address -replace 'SMTP:', 'smtp:'
        }
        # Remove the address if it already exists (to avoid duplicates)
        if ($address -ne "smtp:$emailAddressOnly" -and $address -ne "SMTP:$emailAddressOnly") {
            $proxyAddresses += $address
        }
    }
    # Add the new proxy address
    $proxyAddresses += $distributionGroupProxyAddress

    #region update distribution group
    $actionMessage = "updating distribution group"

    $UpdateDistributionGroupParams = @{
        Identity                        = $distributionGroup.Guid
        DisplayName                     = $distributionGroupDisplayName
        Name                            = $distributionGroupDisplayName
        EmailAddresses                  = $proxyAddresses
        Alias                           = $distributionGroupAlias
        EmailAddressPolicyEnabled = $false
        Confirm = $false
        ErrorAction                     = 'Stop'
    }

    $null = Set-DistributionGroup @UpdateDistributionGroupParams
 
    Write-Information  "Distribution Group [$distributionGroupDisplayName] updated successfully" 
    $Log = @{
        Action            = "UpdateResource" # optional. ENUM (undefined = default) 
        System            = "Exchange On-Premises" # optional (free format text) 
        Message           = "Distribution Group [$distributionGroupDisplayName] updated successfully"  # required (free format text) 
        IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
        TargetDisplayName = $distributionGroupDisplayName # optional (free format text) 
        TargetIdentifier  = $([string]$($distributionGroup.Guid)) # optional (free format text) 
    }
    #send result back  
    Write-Information -Tags "Audit" -MessageData $log 
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

    # Send error audit log to HelloID
    $Log = @{
        Action            = "UpdateResource" # optional. ENUM (undefined = default) 
        System            = "Exchange On-Premises" # optional (free format text) 
        Message           = $auditMessage # required (free format text) 
        IsError           = $true # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
        TargetDisplayName = $distributionGroupDisplayName # optional (free format text) 
        TargetIdentifier  = $([string]$($distributionGroup.Guid)) # optional (free format text) 
    }
    
    Write-Information -Tags "Audit" -MessageData $log
    Write-Warning $warningMessage
    Write-Error $auditMessage
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

            # Send disconnect audit log
            $Log = @{
                Action            = "UpdateResource" # optional. ENUM (undefined = default) 
                System            = "Exchange On-Premises" # optional (free format text) 
                Message           = "Successfully disconnected from Exchange using URI [$ExchangeConnectionUri]" # required (free format text) 
                IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
                TargetDisplayName = $ExchangeConnectionUri # optional (free format text) 
                TargetIdentifier  = $([string]$exchangeSession.InstanceId) # optional (free format text) 
            }
            Write-Information -Tags "Audit" -MessageData $log
        }
        catch {
            Write-Warning "Failed to disconnect from Exchange using URI [$ExchangeConnectionUri]. Error: $($_.Exception.Message)"
        }
    }
}
