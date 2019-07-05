# RDS Connection Broker

## Definition of the parameters

- IsAdvancedRDSDeployment: ('Yes', 'No') You can deploy RDS in 2 ways: Simple and Advanced. This is what you declare here.
- LabPath: The Path where the LabXML Files are
- RDSCBComputerName: The Name of the VM where the RDS Gateway Role should be installed on
- ConnectionBrokerHighAvailabilty: ('Yes', 'No')

## Defining the role

```` PowerShell
$role_cb = Get-LabPostInstallationActivity -CustomRole RDSCB -Properties @{
    IsAdvancedRDSDeployment         = 'Yes'
    ConnectionBrokerHighAvailabilty = 'Yes'
    LabPath                         = $labPath
    RDSCBComputerName               = 'ALRDSCB'
}
Add-LabMachineDefinition -Name ALRDSCB -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -DomainName contoso.com -PostInstallationActivity $role_cb
````