param
(
    [String]
    [ValidateSet('Yes', 'No')]
    $IsAdvancedRDSDeployment,
    
    [Parameter(Mandatory = $false)]
    [String]
    $RDSGWComputerName,

    [Parameter(Mandatory)]
    [String]
    $LabPath
)

Import-Lab -Path $LabPath -NoValidation

switch ($IsAdvancedRDSDeployment)
{
    'Yes'
    {
        Invoke-LabCommand -ComputerName $RDSGWComputerName -ActivityName 'Installing RSAT-AD-PowerShell' -ScriptBlock {
            Install-WindowsFeature -Name 'RSAT-AD-PowerShell'
        }

        Invoke-LabCommand -ComputerName $RDSGWComputerName -ActivityName "Move Computer to the right OU in AD" -ScriptBlock {
            Import-Module ActiveDirectory
            $dn = (Get-ADDomain).DistinguishedName
            $computerName = $env:COMPUTERNAME
            $pc_path = (Get-ADComputer -Identity $computerName).DistinguishedName
            $targetpath_partone = ("OU=RDSGW,OU=RDS,")
            $targetpath = [String]::Concat("$targetpath_partone", $dn)

            $domainName = (Get-ADDomain).DNSRoot
            $domaincontroller = (Get-ADDomainController -DomainName $domainName -Discover).HostName | Select-Object -First 1

            if ($dn -eq $targetpath)
            {
                Write-ScreenInfo "Computer $computerName is already in the right OU ($targetpath)."
            }
            else
            {
                Write-Output "Moving Computer $computername to the path $targetpath."
                Move-ADObject -Identity $pc_path -TargetPath $targetpath -Server $domaincontroller
            }
        }

        $isInstalled_CBRole = (Get-LabWindowsFeature -FeatureName "RDS-Gateway" -ComputerName $RDSGWComputerName -NoDisplay).InstallState

        if ($isInstalled_CBRole -eq "Installed") 
        {
            Write-Output -Message "RDS Gateway Role is already installed."
        }
        else 
        {
            Write-ScreenInfo -Message "Installing Feature for RDS Gateway"                     
            Install-LabWindowsFeature -ComputerName $RDSGWComputerName -FeatureName "RDS-Gateway" -IncludeAllSubFeature -IncludeManagementTools
        }
    }

    'No'
    {
        Write-Output "It is not an advanced deployment. No action needed."
    }
}