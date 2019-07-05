param
(
    [String]
    [ValidateSet('Yes', 'No')]
    $IsAdvancedRDSDeployment,
    
    [Parameter(Mandatory)]
    [String]
    [ValidateSet('Yes', 'No')]
    $ConnectionBrokerHighAvailabilty,

    [Parameter(Mandatory = $false)]
    [String]
    $RDSCBComputerName,

    [Parameter(Mandatory)]
    [String]
    $LabPath
)

Import-Lab -Path $LabPath -NoValidation

switch ($IsAdvancedRDSDeployment)
{
    'Yes'
    {
        switch ($ConnectionBrokerHighAvailabilty)
        {
            'Yes'
            {
                Invoke-LabCommand -ComputerName $RDSCBComputerName -ActivityName 'Installing RSAT-AD-PowerShell' -ScriptBlock {
                    Install-WindowsFeature -Name 'RSAT-AD-PowerShell'
                }

                Invoke-LabCommand -ComputerName $RDSCBComputerName -ActivityName "Move Computer to the right OU in AD" -ScriptBlock {
                    Import-Module ActiveDirectory
                    $dn = (Get-ADDomain).DistinguishedName
                    $computerName = $env:COMPUTERNAME
                    $pc_path = (Get-ADComputer -Identity $computerName).DistinguishedName
                    $targetpath_partone = ("OU=RDSCB,OU=RDS,")
                    $targetpath = [String]::Concat("$targetpath_partone", $dn)

                    $domainName = (Get-ADDomain).DNSRoot
                    $domaincontroller = (Get-ADDomainController -DomainName $domainName -Discover).HostName | Select-Object -First 1

                    if ($dn -eq $targetpath)
                    {
                        Write-Output "Computer $computerName is already in the right OU ($targetpath)."
                    }
                    else
                    {
                        Write-Output "Moving Computer $computername to the path $targetpath."
                        Move-ADObject -Identity $pc_path -TargetPath $targetpath -Server $domaincontroller
                    }
                }

                $isInstalled_CBRole = (Get-LabWindowsFeature -FeatureName "RDS-Connection-Broker" -ComputerName $RDSCBComputerName).State

                if ($isInstalled_CBRole -eq "Installed") 
                {
                    Write-ScreenInfo -Message "RDS Connection Broker Role is already installed."
                }
                else 
                {                    
                    Write-ScreenInfo -Message "Installing Feature for RDS Connection Broker"
                    Install-LabWindowsFeature -ComputerName $RDSCBComputerName -FeatureName "RDS-Connection-Broker" -IncludeAllSubFeature -IncludeManagementTools
                }

                Invoke-LabCommand -ComputerName $RDSCBComputerName -ActivityName "Add ConnectionBroker $RDSCBComputerName to group G_ConnectionBrokerServers" -ScriptBlock {
                    Import-Module ActiveDirectory
                    $computerName = $env:COMPUTERNAME
                    $pc_path = (Get-ADComputer -Identity $computerName).DistinguishedName
                    
                    $domainName = (Get-ADDomain).DNSRoot
                    $domaincontroller = (Get-ADDomainController -DomainName $domainName -Discover).HostName | Select-Object -First 1
                    
                    Add-ADGroupMember -Identity "G_ConnectionBrokerServers" -Members $pc_path -Server $domaincontroller
                }
            }
                    
            'No'
            {
                Invoke-LabCommand -ComputerName $RDSCBComputerName -ActivityName 'Installing RSAT-AD-PowerShell' -ScriptBlock {
                    Install-WindowsFeature -Name 'RSAT-AD-PowerShell'
                }

                Invoke-LabCommand -ComputerName $RDSCBComputerName -ActivityName "Move Computer to the right OU in AD" -ScriptBlock {
                    Import-Module ActiveDirectory
                    $dn = (Get-ADDomain).DistinguishedName
                    $computerName = $env:COMPUTERNAME
                    $pc_path = (Get-ADComputer -Identity $computerName).DistinguishedName
                    $targetpath_partone = ("OU=RDSCB,OU=RDS,")
                    $targetpath = [String]::Concat("$targetpath_partone", $dn)

                    $domainName = (Get-ADDomain).DNSRoot
                    $domaincontroller = (Get-ADDomainController -DomainName $domainName -Discover).HostName | Select-Object -First 1

                    if ($dn -eq $targetpath)
                    {
                        Write-Output "Computer $computerName is already in the right OU ($targetpath)."
                    }
                    else
                    {
                        Write-Output "Moving Computer $computername to the path $targetpath."
                        Move-ADObject -Identity $pc_path -TargetPath $targetpath -Server $domaincontroller
                    }
                }

                $isInstalled_CBRole = (Get-LabWindowsFeature -FeatureName "RDS-Connection-Broker" -ComputerName $RDSCBComputerName -NoDisplay).InstallState

                if ($isInstalled_CBRole -eq "Installed") 
                {
                    Write-Output -Message "RDS Connection Broker Role is already installed."
                }
                else 
                {                    
                    Write-ScreenInfo -Message "Installing Feature for RDS Connection Broker"
                    Install-LabWindowsFeature -ComputerName $RDSCBComputerName -FeatureName "RDS-Connection-Broker" -IncludeAllSubFeature -IncludeManagementTools
                }
            }
        }
    }

    'No'
    {
        Write-Output "It is not an advanced deployment. No action needed."
    }
}