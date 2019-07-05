# RDS Domain Structure

# Definition of the parameters
- IsAdvancedRDSDeployment: ('Yes', 'No') You can deploy RDS in 2 ways: Simple and Advanced. This is what you declare here.
- ConnectionBrokerHighAvailabilty:  ('Yes', 'No')
- LabPath: The Path where the LabXML Files are

# Defining the role

```` PowerShell
$role_dc = Get-LabPostInstallationActivity -CustomRole RDSAD -Properties @{
    IsAdvancedRDSDeployment         = 'Yes'
    ConnectionBrokerHighAvailabilty = 'Yes'
    LabPath                         = $labPath
}
Add-LabMachineDefinition -Name ALDC -Memory 1GB -Roles RootDC -IpAddress 192.168.0.10 -PostInstallationActivity $role_dc
````