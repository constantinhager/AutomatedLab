# RDS Gateway

## Definition of the parameters

- IsAdvancedRDSDeployment: ('Yes', 'No') You can deploy RDS in 2 ways: Simple and Advanced. This is what you declare here.
- LabPath: The Path where the LabXML Files are
- RDSGWComputerName: The Name of the VM where the RDS Gateway Role should be installed on.

## Defining the role

```` PowerShell
$role_gw = Get-LabPostInstallationActivity -CustomRole RDSGW -Properties @{
    IsAdvancedRDSDeployment = 'Yes'
    LabPath                 = $labPath
    RDSGWComputerName       = 'ALRDSGW'
}
Add-LabMachineDefinition -Name ALRDSGW -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -DomainName contoso.com -PostInstallationActivity $role_gw
````