param
(
    [String]
    [ValidateSet('Yes', 'No')]
    $IsAdvancedRDSDeployment,
    
    [Parameter(Mandatory = $false)]
    [String]
    $RDSLICComputerName,

    [Parameter(Mandatory)]
    [String]
    $LabPath
)

Import-Lab -Path $LabPath -NoValidation

switch ($IsAdvancedRDSDeployment)
{
    'Yes'
    {
        Invoke-LabCommand -ComputerName $RDSLICComputerName -ActivityName 'Installing RSAT-AD-PowerShell' -ScriptBlock {
            Install-WindowsFeature -Name 'RSAT-AD-PowerShell'
        }

        Invoke-LabCommand -ComputerName $RDSLICComputerName -ActivityName "Move Computer to the right OU in AD" -ScriptBlock {
            Import-Module ActiveDirectory
            $dn = (Get-ADDomain).DistinguishedName
            $computerName = $env:COMPUTERNAME
            $pc_path = (Get-ADComputer -Identity $computerName).DistinguishedName
            $targetpath_partone = ("OU=RDSLIC,OU=RDS,")
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

        $isInstalled_CBRole = (Get-LabWindowsFeature -FeatureName "RDS-Licensing" -ComputerName $RDSLICComputerName -NoDisplay).InstallState

        if ($isInstalled_CBRole -eq "Installed") 
        {
            Write-Output -Message "RDS Licensing is already installed."
        }
        else 
        {
            Write-ScreenInfo -Message "Installing Feature for RDS Licensing"                    
            Install-LabWindowsFeature -ComputerName $RDSLICComputerName -FeatureName "RDS-Licensing" -IncludeAllSubFeature -IncludeManagementTools
        }
    }

    'No'
    {
        Write-Output "It is not an advanced deployment. No action needed."
    }
}