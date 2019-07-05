function New-OUSubfolderStructure
{    
    param
    (
        [Parameter(Mandatory)]
        [String]
        $DN,

        [Parameter(Mandatory)]
        [String[]]
        $Folderstructure
    )

    foreach ($folder in $Folderstructure)
    {
        $DN_folder = [String]::Concat("OU=$folder,", $DN)
        
        if (Get-OUState -DN $DN_folder)
        {
            Write-Output -InputObject "OU $Folder exists already."
        }
        else
        {
            Write-Output -InputObject "Going to create OU $folder in path $DN"
            New-ADOrganizationalUnit -Name "$folder" -Path $DN
        }
    }
}

function Get-OUState
{
    Param
    (
        [Parameter(Mandatory)]
        [String]
        $DN
    )
    
    try
    {
        Get-ADOrganizationalUnit -Identity $DN -ErrorAction SilentlyContinue
        return $true
    }
    catch
    {
        return $false
    }
}

function Get-ADGroupState
{
    Param
    (
        [Parameter(Mandatory)]
        [String]
        $DN
    )
    
    try
    {
        Get-ADGroup -Identity $DN -ErrorAction SilentlyContinue
        return $true
    }
    catch
    {
        return $false
    }
}

function New-ADStructure
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $ConnectionBrokerHighAvailabilty
    )

    $dn = (Get-ADDomain).DistinguishedName
    $dn_rds = [String]::Concat("OU=RDS,", $dn)
    $subfolders = "RDSBD", "RDSFS", "RDSGW", "RDSSH", "RDSGroups", "RDSCB", "RDSLIC"

    try
    {
        $null = Get-ADOrganizationalUnit -Identity $dn_rds -ErrorAction SilentlyContinue
        Write-Output -InputObject "OU RDS already exists."
        Write-Output -InputObject "Check if subfolders are missing."
        New-OUSubfolderStructure -DN $dn_rds -Folderstructure $subfolders
        if ($ConnectionBrokerHighAvailabilty)
        {
            $group_rdsconnectionbroker = [String]::Concat("CN=G_ConnectionBrokerServers,", $dn_rds)
            if (Get-ADGroupState -DN $group_rdsconnectionbroker)
            {
                Write-Output -InputObject "Global Group G_ConnectionBrokerServers already exists."
            }
            else
            {
                Write-Output -InputObject "Global Group G_ConnectionBrokerServers will be created."
                New-ADGroup -Name "G_ConnectionBrokerServers" -GroupScope Global -GroupCategory Security -SamAccountName "G_ConnectionBrokerServers" -Path $dn_rds       
            }       
        }
    }
    catch 
    {
        Write-Output -InputObject "OU Structure not there Create it"
   
        Write-Output -InputObject "Create A New Folderstructure."
        New-ADOrganizationalUnit -Name "RDS" -Path $dn -Description "Entrypoint for RDS AD Structure"
        New-OUSubfolderStructure -DN $dn_rds -Folderstructure $subfolders

        if ($ConnectionBrokerHighAvailabilty)
        {
            $group_rdsconnectionbroker = [String]::Concat("CN=G_ConnectionBrokerServers,", $dn_rds)
            if (Get-ADGroupState -DN $group_rdsconnectionbroker)
            {
                Write-Output -InputObject "Global Group G_ConnectionBrokerServers already exists."
            }
            else
            {
                Write-Output -InputObject "Global Group G_ConnectionBrokerServers will be created."
                New-ADGroup -Name "G_ConnectionBrokerServers" -GroupScope Global -GroupCategory Security -SamAccountName "G_ConnectionBrokerServers" -Path $dn_rds       
            }       
        }
    }
}