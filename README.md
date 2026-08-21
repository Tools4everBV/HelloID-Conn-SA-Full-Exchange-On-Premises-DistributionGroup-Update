# HelloID-Conn-SA-Full-Exchange-On-Premises-Distribution-Group-Update

| :information_source: Information                                                                                                                                                                                                                                                                                                                                                          |
| :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| This repository contains the connector and configuration code only. The implementer is responsible for acquiring the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements. |

## Description

_HelloID-Conn-SA-Full-Exchange-On-Premises-Distribution-Group-Update_ is a template designed for use with HelloID Service Automation (SA) Delegated Forms. It can be imported into HelloID and customized according to your requirements.

By using this delegated form, you can manage distribution group attributes in Exchange On-Premises. The following options are available:

1.  Search and select a distribution group
2.  Enter new values for the distribution group attributes (DisplayName, Alias, Email Address)
3.  The entered values are validated for uniqueness
4.  Distribution group attributes are updated with new values
5.  Email addresses are managed while preserving existing proxy addresses

## Getting started

### Requirements

- **Exchange On-Premises Environment**:<br>
  A functioning Exchange On-Premises environment with PowerShell remoting enabled. The Exchange server must be accessible from the HelloID agent.
- **Service Account**:<br>
  A service account with sufficient permissions to manage distribution groups in Exchange On-Premises. The account must have permissions to use the `Get-DistributionGroup` and `Set-DistributionGroup` cmdlets.
- **HelloID Agent**:<br>
  The HelloID agent must be installed on a server that can establish a PowerShell remoting session to the Exchange server.

### Connection settings

The following Global Variables are used by the connector and must be configured in HelloID.

| Setting               | Description                                                                          | Mandatory |
| --------------------- | ------------------------------------------------------------------------------------ | --------- |
| ExchangeConnectionUri | The URI to connect to Exchange (e.g., http://exchangeserver.domain.local/powershell) | Yes       |
| ExchangeAdminUsername | The username of the service account                                                  | Yes       |
| ExchangeAdminPassword | The password of the service account                                                  | Yes       |

## Remarks

### Email Address Management

- **Preserving Proxy Addresses**: When adding a new email address to a distribution group, all existing proxy addresses are preserved. The connector intelligently manages primary and secondary SMTP addresses.
- **Primary Email Handling**: When setting an email address as primary (SMTP in uppercase), any existing primary address is automatically converted to a secondary address (smtp in lowercase).
- **Duplicate Prevention**: The connector checks for and prevents duplicate email addresses before adding new ones.

### Active Directory Integration

- **DisplayName Validation**: The connector includes a datasource to validate that the DisplayName is unique in Active Directory before updating the distribution group.

### PowerShell Remoting Requirements

- **Session Options**: The connector uses strict SSL/TLS validation with certificate checking enabled (`SkipCACheck`, `SkipCNCheck`, and `SkipRevocationCheck` are all set to `$false`). Ensure your Exchange server has a valid SSL certificate if required.
- **Authentication Method**: The connector uses Default authentication when connecting to Exchange On-Premises.

### Email Address Policy

- **Policy Disabled**: The connector explicitly disables the Email Address Policy (`EmailAddressPolicyEnabled = $false`) when updating distribution groups to prevent automatic overwrites of manually configured addresses.

## Development resources

### API endpoints

The following Exchange PowerShell cmdlets are used by the connector:

| Cmdlet                | Description                             |
| --------------------- | --------------------------------------- |
| Get-DistributionGroup | Retrieve distribution group information |
| Set-DistributionGroup | Update distribution group properties    |
| Get-AcceptedDomain    | Retrieve accepted email domains         |

### API documentation

- [Exchange PowerShell Documentation](https://learn.microsoft.com/en-us/powershell/exchange/)
- [Connect to Exchange Servers using Remote PowerShell](https://learn.microsoft.com/en-us/powershell/exchange/connect-to-exchange-servers-using-remote-powershell)
- [Get-DistributionGroup](https://learn.microsoft.com/en-us/powershell/module/exchange/get-distributiongroup)
- [Set-DistributionGroup](https://learn.microsoft.com/en-us/powershell/module/exchange/set-distributiongroup)

## Getting help

> :bulb: **Tip:**  
> _For more information on Delegated Forms, please refer to our [documentation](https://docs.helloid.com/en/service-automation/delegated-forms.html) pages_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
