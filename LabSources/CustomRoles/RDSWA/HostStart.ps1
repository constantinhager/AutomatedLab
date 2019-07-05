param
(
    [String]
    [ValidateSet('Yes', 'No')]
    $IsAdvancedRDSDeployment,
    
    [Parameter(Mandatory = $false)]
    [String]
    $RDSWAComputerName,

    [Parameter(Mandatory)]
    [String]
    $LabPath
)

Import-Lab -Path $LabPath -NoValidation

switch ($IsAdvancedRDSDeployment)
{
    'Yes'
    {
        Invoke-LabCommand -ComputerName $RDSWAComputerName -ActivityName 'Installing RSAT-AD-PowerShell' -ScriptBlock {
            Install-WindowsFeature -Name 'RSAT-AD-PowerShell'
        }

        $isInstalled_CBRole = (Get-LabWindowsFeature -FeatureName "RDS-Web-Access" -ComputerName $RDSWAComputerName -NoDisplay).InstallState

        if ($isInstalled_CBRole -eq "Installed") 
        {
            Write-Output -Message "RDS Web Access Role is already installed."
        }
        else 
        {   
            Write-ScreenInfo -Message "Installing Feature for RDS Web Access"                 
            Install-LabWindowsFeature -ComputerName $RDSWAComputerName -FeatureName "RDS-Web-Access" -IncludeAllSubFeature -IncludeManagementTools
        }
    }

    'No'
    {
        Write-Output "It is not an advanced deployment. No action needed."
    }
}