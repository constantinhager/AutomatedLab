# RDS License Server

## Definition of the parameters
- IsAdvancedRDSDeployment: ('Yes', 'No') You can deploy RDS in 2 ways: Simple and Advanced. This is what you declare here.
- LabPath: The Path where the LabXML Files are
- RDSLICComputerName: The Name of the VM where the RDS License Server Role should be installed on.

## Defining the Role
```` PowerShell
$role_lic = Get-LabPostInstallationActivity -CustomRole RDSLIC -Properties @{
    IsAdvancedRDSDeployment = 'Yes'
    LabPath                 = $labPath
    RDSLICComputerName      = 'ALRDSLIC'
}
Add-LabMachineDefinition -Name ALRDSLIC -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -DomainName contoso.com -PostInstallationActivity $role_lic
````