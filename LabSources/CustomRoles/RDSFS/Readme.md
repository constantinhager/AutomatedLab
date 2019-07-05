# RDS File Services

You have 2 choices of storing RDS User Profiles
- UserProfileDisks (new way)
- Roaming Profiles (old way)

You can use both ways with this role.

## Definition of the parameters

- IsAdvancedRDSDeployment,
- LabPath,

For Roaming Profiles:
- UseRoamingProfiles: ('Yes', 'No')
- RoamingProfilePath: The base Path for the roaming profiles.
- SessionBasedDesktopRoamingProfilePath: If a Session based Desktop is in your deployment you have to use this path as well.

For User Profile Disks:
- UseUserProfileDisks: ('Yes', 'No')
- UserProfileDiskPath: The base Path for the user profile disks.
- SessionBasedDesktopUserProfileDiskPath: If a Session based Desktop is in your deployment you have to use this path as well.

For Both scenarios
- HasSessionBasedDesktop: Define if you have a Session based Desktop in your environment.

## Defining Use User Profile Disks

```` PowerShell
$role_fs = Get-LabPostInstallationActivity -CustomRole RDSFS -Properties @{
    IsAdvancedRDSDeployment                = 'Yes'
    LabPath                                = $labPath
    HasSessionBasedDesktop                 = 'Yes'
    UseUserProfileDisks                    = 'Yes'
    UserProfileDiskPath                    = 'C:\UserProfileDisks'
    SessionBasedDesktopUserProfileDiskPath = 'C:\UserProfileDisksSessionBasedDesktop'
}
Add-LabMachineDefinition -Name ALFS -Memory 1GB -Roles FileServer -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -DomainName contoso.com -PostInstallationActivity $role_fs
````

## Defining Use User Profile Disks Without a Session Based Desktop

```` PowerShell
$role_fs = Get-LabPostInstallationActivity -CustomRole RDSFS -Properties @{
    IsAdvancedRDSDeployment                = 'Yes'
    LabPath                                = $labPath
    UseUserProfileDisks                    = 'Yes'
    UserProfileDiskPath                    = 'C:\UserProfileDisks'
}
Add-LabMachineDefinition -Name ALFS -Memory 1GB -Roles FileServer -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -DomainName contoso.com -PostInstallationActivity $role_fs
````

## Defining Use Roaming Profiles

```` PowerShell
$role_fs = Get-LabPostInstallationActivity -CustomRole RDSFS -Properties @{
    IsAdvancedRDSDeployment                = 'Yes'
    LabPath                                = $labPath
    HasSessionBasedDesktop                 = 'Yes'
    UseRoamingProfiles                     = 'Yes'
    RoamingProfilePath                     = 'C:\RoamingProfiles'
    SessionBasedDesktopRoamingProfilePath  = 'C:\RoamingProfilesSessionBasedDesktop'
}
Add-LabMachineDefinition -Name ALFS -Memory 1GB -Roles FileServer -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -DomainName contoso.com -PostInstallationActivity $role_fs
````

## Defining Use Roaming Profiles without a Session Based Desktop

```` PowerShell
$role_fs = Get-LabPostInstallationActivity -CustomRole RDSFS -Properties @{
    IsAdvancedRDSDeployment                = 'Yes'
    LabPath                                = $labPath
    UseRoamingProfiles                     = 'Yes'
    RoamingProfilePath                     = 'C:\RoamingProfiles'
}
Add-LabMachineDefinition -Name ALFS -Memory 1GB -Roles FileServer -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -DomainName contoso.com -PostInstallationActivity $role_fs
````