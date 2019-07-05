param
(
    [String]
    [ValidateSet('Yes', 'No')]
    $IsAdvancedRDSDeployment,
    
    [Parameter(Mandatory = $false)]
    [String]
    $RDSSHComputerName,

    [Parameter(Mandatory)]
    [String]
    [ValidateSet('Yes', 'No')]
    $IsSessionBasedDesktop,

    [Parameter(Mandatory)]
    [String]
    $LabPath
)

Import-Lab -Path $LabPath -NoValidation

switch ($IsAdvancedRDSDeployment)
{
    'Yes'
    {
        Invoke-LabCommand -ComputerName $RDSSHComputerName -ActivityName 'Installing RSAT-AD-PowerShell' -ScriptBlock {
            Install-WindowsFeature -Name 'RSAT-AD-PowerShell'
        }

        Invoke-LabCommand -ComputerName $RDSSHComputerName -ActivityName "Move Computer to the right OU in AD" -ScriptBlock {
            Import-Module ActiveDirectory
            $dn = (Get-ADDomain).DistinguishedName
            $computerName = $env:COMPUTERNAME
            $pc_path = (Get-ADComputer -Identity $computerName).DistinguishedName
            
            if ($args[0] -eq 'Yes')
            {
                $targetpath = [String]::Concat("OU=RDSBD,OU=RDS,", $dn)
                $OuNameDN = [String]::Concat("OU=RDSGroups,", "OU=RDS,", $dn)
                try
                {
                    Get-ADGroup -Identity "DL_SBD"
                }
                catch
                {
                    New-ADGroup -Name "DL_SBD" -SamAccountName "DL_SBD" -GroupCategory Security -GroupScope DomainLocal -DisplayName "DL_SBD" -Path $OuNameDN
                }                
            }
            else
            {
                $targetpath = [String]::Concat("OU=RDSSH,OU=RDS,", $dn)
            }
                        
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
        } -ArgumentList $IsSessionBasedDesktop

        $isInstalled_CBRole = (Get-LabWindowsFeature -FeatureName "RDS-RD-Server" -ComputerName $RDSSHComputerName -NoDisplay).InstallState

        if ($isInstalled_CBRole -eq "Installed") 
        {
            Write-Output -Message "RDS Session Host Role is already installed."
        }
        else 
        {                    
            Write-ScreenInfo -Message "Installing Feature for RDS Session Host" 
            Install-LabWindowsFeature -ComputerName $RDSSHComputerName -FeatureName "RDS-RD-Server" -IncludeAllSubFeature -IncludeManagementTools
            Restart-LabVM -ComputerName $RDSSHComputerName -Wait
        }
    }

    'No'
    {
        Write-Output "It is not an advanced deployment. No action needed."
    }
}