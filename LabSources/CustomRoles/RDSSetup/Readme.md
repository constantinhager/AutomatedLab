# RDS Setup

## Defintion of the parameters

- IsAdvancedRDSDeployment         : ('Yes', 'No') You can deploy RDS in 2 ways: Simple and Advanced. This is what you declare here.
- ConnectionBrokerHighAvailabilty : ('Yes', 'No')
- RDSDNSName                      : The web address where the Web Frontend will be reachable through your browser.
- LabPath                         : The Path where the LabXML Files are
- LogOnMethod                     : ('Password', 'AllowUserToSelectDuringConnection', 'Smartcard'). Standard is 'Password'
- ByPassLocal                     : ('Yes', 'No'). Standard is 'No'
- UseCachedCredentials            : ('Yes', 'No'). Standard is 'Yes'
- GatewayMode                     : ('DoNotUse', 'Custom', 'Automatic'). Standard is 'Custom'
- LicensingMode                   : ('PerDevice', 'PerUser', 'NotConfigured'). Standard is 'PerUser'

## Defining the role

```` PowerShell
$role_rdssetup = Get-LabPostInstallationActivity -CustomRole RDSSetup -Properties @{
    IsAdvancedRDSDeployment         = 'Yes'
    ConnectionBrokerHighAvailabilty = 'Yes'
    RDSDNSName                      = 'rds.dev.com'
    LabPath                         = $labpath
    LogOnMethod                     = 'Password'
    ByPassLocal                     = 'No'
    UseCachedCredentials            = 'Yes'
    GatewayMode                     = 'Custom'
    LicensingMode                   = 'PerUser'
}
Add-LabMachineDefinition -Name ALRDSSH -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -DomainName contoso.com -PostInstallationActivity $role_sh, $role_rdssetup
````