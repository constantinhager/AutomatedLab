# RDS Session Host

In a RDS deployment there can be 2 flavours of Session Host Servers:

- RDS Session Host for Session Based Desktops (Full Desktop Experience)
- RDS Session Host for Application only Deployments

Both of this you can implement with this Role.

## Definition of the Parameters
- IsAdvancedRDSDeployment: ('Yes', 'No') You can deploy RDS in 2 ways: Simple and Advanced. This is what you declare here.
- LabPath: The Path where the LabXML Files are
- RDSSHComputerName: The Name of the VM where the RDS Session Host Role should be installed on.
- IsSessionBasedDesktop: ('Yes', 'No') Defines if this is a Session host where only a full desktop is serviced or not

## Defining RDS Session Host for Session Based Desktops

```` PowerShell
$role_sbd = Get-LabPostInstallationActivity -CustomRole RDSSH -Properties @{
    IsAdvancedRDSDeployment = 'Yes'
    LabPath                 = $labPath
    RDSSHComputerName       = 'ALRDSSBD'
    IsSessionBasedDesktop   = 'Yes'
}

Add-LabMachineDefinition -Name ALRDSSBD -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -DomainName contoso.com -PostInstallationActivity $role_sbd
````

## Defining RDS Session Host for Application only Deployments

```` PowerShell
$role_sh = Get-LabPostInstallationActivity -CustomRole RDSSH -Properties @{
    IsAdvancedRDSDeployment = 'Yes'
    LabPath                 = $labPath
    RDSSHComputerName       = 'ALRDSSH'
    IsSessionBasedDesktop   = 'No'
}

Add-LabMachineDefinition -Name ALRDSSH -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -DomainName contoso.com -PostInstallationActivity $role_sh
````