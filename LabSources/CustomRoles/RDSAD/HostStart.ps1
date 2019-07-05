param
(
    [String]
    [ValidateSet('Yes', 'No')]
    $IsAdvancedRDSDeployment,    

    [Parameter(Mandatory)]
    [String]
    [ValidateSet('Yes', 'No')]
    $ConnectionBrokerHighAvailabilty,

    [Parameter(Mandatory)]
    [String]
    $LabPath
)

Import-Lab -Path $LabPath

switch ($IsAdvancedRDSDeployment)
{
    'Yes'
    {
        if (Get-Module -Name InstallRDSAD -ErrorAction SilentlyContinue)
        {
            Remove-Module InstallRDSAD
            Import-Module $PSScriptRoot\InstallRDSAD.psm1
        }
        else
        {
            Import-Module $PSScriptRoot\InstallRDSAD.psm1
        }
                
        $module = Get-Command -Module InstallRDSAD
        $rootdcname = Get-LabVM -Role RootDC | Select-Object -First 1 -ExpandProperty Name
        
        Invoke-LabCommand -ComputerName $rootdcname -ActivityName 'Creating RDS ActiveDirectory Structure' -ScriptBlock {
            New-ADStructure -ConnectionBrokerHighAvailabilty $args[0]
        } -Function $module -ArgumentList $ConnectionBrokerHighAvailabilty              
    }

    'No'
    {
        Write-Output "It is not an advanced deployment. No structure needed."
    }
}