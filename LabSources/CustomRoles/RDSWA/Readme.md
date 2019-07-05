# RDS Web Access Server Role

Installs the RDS Web Access Server Role on a Server 2016

## Definition of the parameters

- Is AdvancedRDSDeployment: ('Yes', 'No') You can deploy RDS in 2 ways: Simple and Advanced. This is what you declare here.
- LabPath: The Path where the LabXML Files are
- RDSWAComputerName: The Name of the VM where the Web Access Server Role should be installed on.

## Defining the role

```` PowerShell
$role_wa = Get-LabPostInstallationActivity -CustomRole RDSWA -Properties @{
    IsAdvancedRDSDeployment = 'Yes'
    LabPath                 = $labPath
    RDSWAComputerName       = 'ALRDSGW'
}

Add-LabMachineDefinition -Name ALRDSGW -Memory 1GB -IpAddress 192.168.0.12 -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -DomainName contoso.com -PostInstallationActivity $role_wa
````

In the lab the Web Access Server needs to be on the same Server as the
RDS Gateway Server.

So a full setup would look like this:

```` PowerShell
$role_wa = Get-LabPostInstallationActivity -CustomRole RDSWA -Properties @{
    IsAdvancedRDSDeployment = 'Yes'
    LabPath                 = $labPath
    RDSWAComputerName       = 'ALRDSGW'
}

$role_gw = Get-LabPostInstallationActivity -CustomRole RDSGW -Properties @{
    IsAdvancedRDSDeployment = 'Yes'
    LabPath                 = $labPath
    RDSGWComputerName       = 'ALRDSGW'
}
Add-LabMachineDefinition -Name ALRDSGW -Memory 1GB -IpAddress 192.168.0.12 -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -DomainName contoso.com -PostInstallationActivity $role_gw, $role_wa
````