function Add-LabRDSConnectionBrokerHA
{
    param
    (
        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $LabName,

        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $FirstConnectionBroker,

        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $ConnectionBrokerInternalName,

        [Parameter(Mandatory)]
        [string]
        $ConnectionBrokerDNSInternalZone,

        [Parameter(Mandatory)]
        [string]
        $SQLServerName,

        [Parameter(Mandatory)]
        [string]
        $SQLServerHADataBaseName
    )

    Install-LabSQLClient -LabName $LabName
    
    $setLabRDPublishedNameSplat = @{
        LabName          = $LabName
        DNSInternalZone  = $ConnectionBrokerDNSInternalZone
        DNSInternalName  = $ConnectionBrokerInternalName
        ConnectionBroker = $FirstConnectionBroker
    }
    Set-LabRDPublishedName @setLabRDPublishedNameSplat
    
    $AddLabConnectionBrokerToADGroupSplat = @{
        LabName          = $LabName 
        ConnectionBroker = $FirstConnectionBroker
    }
    Add-LabConnectionBrokerToADGroup @AddLabConnectionBrokerToADGroupSplat
    
    $RegisterLabADGroupOnSQLServerSplat = @{
        LabName       = $LabName 
        SQLServerName = $SQLServerName
    }
    Register-LabADGroupOnSQLServer @RegisterLabADGroupOnSQLServerSplat
    
    $InitializeLabConnectionBrokerHASplat = @{        
        LabName          = $LabName
        ConnectionBroker = $FirstConnectionBroker
        SQLServerName    = $SQLServerName
        SQLDatabaseName  = $SQLServerHADataBaseName
        DNSInternalName  = $ConnectionBrokerInternalName
        DNSInternalZone  = $ConnectionBrokerDNSInternalZone
    }
    Initialize-LabConnectionBrokerHA @InitializeLabConnectionBrokerHASplat
    
    $GetLabFreeConnectionBrokersSplat = @{
        LabName          = $LabName 
        ConnectionBroker = $FirstConnectionBroker
    }
    $RemainingServers = Get-LabFreeConnectionBrokers @GetLabFreeConnectionBrokersSplat
    
    foreach($RemainingServer in $RemainingServers)
    {
        $AddLabConnectionBrokerToHASplat = @{
            LabName               = $LabName
            ConnectionBroker      = $FirstConnectionBroker
            ConnectionBrokerToAdd = $RemainingServer
        }
        Add-LabConnectionBrokerToHA @AddLabConnectionBrokerToHASplat
    }

    $ImportLabHACertificatesSplat = @{
        LabName          = $LabName 
        ConnectionBroker = $FirstConnectionBroker
    }
    Import-LabHACertificates @ImportLabHACertificatesSplat
}

# Idea: https://github.com/citrixguyblog/PowerShellRDSDeployment/blob/master/Install_RDSFarm.ps1#L344
# I redesigned It. Functions look better than code only.

function Install-LabSQLClient
{
    [CmdletBinding()]
    param
    (
        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $LabName
    )
    Import-Module AutomatedLab
    Import-Lab -Name $LabName -NoValidation

    $DownloadPath = Join-Path -Path $global:labSources -ChildPath "SoftwarePackages"
    $FullDownloadPath = Join-Path -Path $global:labSources -ChildPath "SoftwarePackages\sqlncli.msi"

    $rootdc = Get-LabVM -Role ADDS | Select-Object -First 1

    $AllConnectionBroker = Invoke-LabCommand -ComputerName $rootdc -ActivityName "Get all Connection Broker Servers from the AD." -ScriptBlock {
        Import-Module ActiveDirectory
        
        $dn = (Get-ADDomain).DistinguishedName
        $rdscb = [String]::Concat("OU=RDSCB,OU=RDS,", $dn)
        
        (Get-AdComputer -SearchBase $rdscb -Filter *).Name
    } -PassThru -NoDisplay

    if (Test-Path -Path $FullDownloadPath)
    {
        Write-ScreenInfo -Message "You have already downloaded the sql client"

        foreach ($ConnectionBroker in $AllConnectionBroker)
        {
            Write-ScreenInfo -Message "Copy SqlClient to $ConnectionBroker"
            Copy-LabFileItem -Path $FullDownloadPath -ComputerName $ConnectionBroker -DestinationFolderPath "C:\Tools"
            Install-LabSoftwarePackage -ComputerName $ConnectionBroker -LocalPath "C:\Tools\sqlncli.msi" -CommandLine "/qn IACCEPTSQLNCLILICENSETERMS=YES /log C:\Tools\sqlncli.log"
        }
    }
    else
    {
        try
        {
            Write-ScreenInfo -Message "Downloading SqlClient from the internet."
            
            $getLabInternetFileSplat = @{
                Uri  = "https://download.microsoft.com/download/8/7/2/872BCECA-C849-4B40-8EBE-21D48CDF1456/ENU/x64/sqlncli.msi"
                Path = $DownloadPath
            }
            Get-LabInternetFile @getLabInternetFileSplat
            
            foreach ($ConnectionBroker in $AllConnectionBroker)
            {
                Write-ScreenInfo -Message "Copy SqlClient to $ConnectionBroker"
                Copy-LabFileItem -Path $FullDownloadPath -ComputerName $ConnectionBroker -DestinationFolderPath "C:\Tools"
                Install-LabSoftwarePackage -ComputerName $ConnectionBroker -LocalPath "C:\Tools\sqlncli.msi" -CommandLine "/qn IACCEPTSQLNCLILICENSETERMS=YES /log C:\Tools\sqlncli.log"
            }
        }
        catch
        {
            Write-ScreenInfo -Message "Something went wrong by downloading the sql client."
        }
        
    }
}
function Set-LabRDPublishedName
{
    [CmdletBinding()]
    param 
    (
        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $DNSInternalName,

        [Parameter(Mandatory)]
        [string]
        $DNSInternalZone,

        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $ConnectionBroker,

        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $LabName
    )

    Import-Module AutomatedLab
    Import-Lab -Name $LabName -NoValidation

    $DownloadPath = Join-Path -Path $global:labSources -ChildPath "SoftwarePackages"
    $FullDownloadPath = Join-Path -Path $global:labSources -ChildPath "SoftwarePackages\Set-RDPublishedName.ps1"

    if (Test-Path -Path $FullDownloadPath)
    {
        Write-ScreenInfo -Message "You have already downloaded Set-RDPublishedName.ps1"

        # Remove Clear-Host from File
        (Get-Content $FullDownloadPath).replace('Clear-Host', '') | Set-Content $FullDownloadPath

        Copy-LabFileItem -Path $FullDownloadPath -ComputerName $ConnectionBroker -DestinationFolderPath "C:\Tools"
        
        Invoke-LabCommand -ActivityName "Change RDPublishedName" -ComputerName $ConnectionBroker -ScriptBlock {
            $RDBrokerDNSInternalName = $args[0]
            $RDBrokerDNSInternalZone = $args[1]
            & "C:\Tools\Set-RDPublishedName.ps1" -ClientAccessName "$RDBrokerDNSInternalName.$RDBrokerDNSInternalZone"
        } -ArgumentList $DNSInternalName, $DNSInternalZone
    }
    else
    {
        try
        {
            Write-ScreenInfo -Message "Downloading Set-RDPublishedName.ps1 from the internet."
            
            $getLabInternetFileSplat = @{
                Uri  = "https://gallery.technet.microsoft.com/Change-published-FQDN-for-2a029b80/file/103829/2/Set-RDPublishedName.ps1"
                Path = $DownloadPath
            }
            Get-LabInternetFile @getLabInternetFileSplat

            # Remove Clear-Host from File
            (Get-Content $FullDownloadPath).replace('Clear-Host', '') | Set-Content $FullDownloadPath

            Copy-LabFileItem -Path $FullDownloadPath -ComputerName $ConnectionBroker -DestinationFolderPath "C:\Tools"
            
            Invoke-LabCommand -ActivityName "Change RDPublishedName" -ComputerName $ConnectionBroker -ScriptBlock {
                $RDBrokerDNSInternalName = $args[0]
                $RDBrokerDNSInternalZone = $args[1]
                & "C:\Tools\Set-RDPublishedName.ps1" -ClientAccessName "$RDBrokerDNSInternalName.$RDBrokerDNSInternalZone"
            } -ArgumentList $DNSInternalName, $DNSInternalZone
        }
        catch
        {
            
        }
    }
}
function Add-LabConnectionBrokerToADGroup 
{
    param
    (
        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $ConnectionBroker,

        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $LabName
    )

    Import-Lab -Name $LabName
    $rootdc = Get-LabVM -Role ADDS | Select-Object -First 1

    Invoke-LabCommand -ComputerName $rootdc -ActivityName "Add $ConnectionBroker to the AD Group G_ConnectionBrokerServers" -ScriptBlock {
        Import-Module ActiveDirectory
        $pc_path = (Get-ADComputer -Identity $args[0]).DistinguishedName
        Add-ADGroupMember -Identity "G_ConnectionBrokerServers" -Members $pc_path
    } -ArgumentList $ConnectionBroker
    
    Restart-LabVM -ComputerName $ConnectionBroker -Wait
}
function Register-LabADGroupOnSQLServer
{
    param
    (
        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $LabName,

        [Parameter(Mandatory)]
        [string]
        $SQLServerName
    )
    
    Import-Module AutomatedLab
    Import-Lab -Name $LabName
    $rootdcname = Get-LabVM -Role ADDS | Select-Object -First 1
    Write-ScreenInfo -Message "Check if $SQLServerName is a SQL Server"
    
    $RoleNames = (Get-Labvm -ComputerName $SQLServerName).Roles | Select-Object -ExpandProperty Name
    
    $NetBios = Invoke-LabCommand -ComputerName $rootdcname -ActivityName "Getting the NetBiosName of the Domain" -ScriptBlock {
        Import-Module ActiveDirectory
        (Get-ADDomain).NetBiosName
    } -PassThru -NoDisplay

    if ($RoleNames.ToString().Contains('SQL') -and (-not([String]::IsNullOrWhiteSpace($NetBios))))
    {
        Invoke-LabCommand -ComputerName $SQLServerName -ActivityName "Adding G_ConnectionBrokerServers to SysAdmin Group." -ScriptBlock {
            $SQLserver = $args[0]
            $NetBiosName = $args[1]

            [void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')
            $server = New-Object Microsoft.SqlServer.Management.Smo.Server("$SQLserver")
            $SqlUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login ($server, "$NetBiosName\G_ConnectionBrokerServers")
            $SqlUser.LoginType = 'WindowsGroup'
            $SqlUser.Create()

            $SvrRole = $server.Roles | Where-Object {$_.Name -eq 'sysadmin'};
            $SvrRole.AddMember("$NetBiosName\G_ConnectionBrokerServers");
        } -ArgumentList $SQLServerName, $NetBios
    }
    else
    {
        Write-ScreenInfo -Message "This is not a valid SQL Server."
    }
}
function Initialize-LabConnectionBrokerHA
{
    param
    (
        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $LabName,

        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $ConnectionBroker,

        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $SQLServerName,

        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $SQLDatabaseName,

        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $DNSInternalName,

        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $DNSInternalZone
    )

    Import-Module AutomatedLab
    Import-Lab -Name $LabName

    $rootdcname = Get-LabVM -Role ADDS | Select-Object -First 1

    $DNSRoot = Invoke-LabCommand -ComputerName $rootdcname -ActivityName "Get the DNSRoot of current Domain" -ScriptBlock {
        Import-Module ActiveDirectory
        (Get-ADDomain).DNSRoot
    } -PassThru -NoDisplay

    Invoke-LabCommand -ComputerName $ConnectionBroker -ActivityName "Configuring Connection Broker HA" -ScriptBlock {
        
        $SqlServer = $args[0]
        $SqlServerDBName = $args[1]
        $DNSInternalName = $args[2]
        $DNSInternalZone = $args[3]
        $ConnectionBroker = $args[4]
        $ConnectionBrokerFQDN = [String]::Concat($ConnectionBroker, ".", $args[5])
        
        Import-Module RemoteDesktopServices

        $setRDConnectionBrokerHighAvailabilitySplat = @{
            DatabaseConnectionString = "DRIVER=SQL Server Native Client 11.0;SERVER=$SQLServer;Trusted_Connection=Yes;APP=Remote Desktop Services Connection Broker;DATABASE=$SQLServerDBName"
            ClientAccessName         = "$DNSInternalName.$DNSInternalZone"
            ConnectionBroker         = $ConnectionBrokerFQDN
        }
        Set-RDConnectionBrokerHighAvailability @setRDConnectionBrokerHighAvailabilitySplat
    } -ArgumentList $SQLServerName, $SQLDatabaseName, $DNSInternalName, $DNSInternalZone, $ConnectionBroker, $DNSRoot
}
function Get-LabFreeConnectionBrokers
{
    param
    (
        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $LabName,

        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $ConnectionBroker
    )

    Import-Module AutomatedLab
    Import-Lab -Name $LabName -NoValidation

    $rootdcname = Get-LabVM -Role ADDS | Select-Object -First 1

    $result = Invoke-LabCommand -ComputerName $rootdcname -ActivityName "Getting the ConnectionBrokerServers that are not joined to the RDS Farm" -ScriptBlock {
        $cb = $args[0]
        $dn = (Get-ADDomain).DistinguishedName
        $rdscb = [String]::Concat("OU=RDSCB,OU=RDS,", $dn)
        Import-Module ActiveDirectory
        (Get-AdComputer -SearchBase "$rdscb" -Filter "Name -ne '$cb'").DNSHostName
    } -ArgumentList $ConnectionBroker -PassThru -NoDisplay

    return $result
}
function Add-LabConnectionBrokerToHA
{
    param
    (
        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $LabName,

        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $ConnectionBroker,

        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $ConnectionBrokerToAdd
    )
    
    Import-Module AutomatedLab
    Import-Lab -Name $LabName -NoValidation

    $rootdcname = Get-LabVM -Role ADDS | Select-Object -First 1

    $DNSRoot = Invoke-LabCommand -ComputerName $rootdcname -ActivityName "Get the DNSRoot of current Domain" -ScriptBlock {
        Import-Module ActiveDirectory
        (Get-ADDomain).DNSRoot
    } -PassThru -NoDisplay

    Invoke-LabCommand -ComputerName $ConnectionBroker -ActivityName "Adding $ConnectionBrokerToAdd To ConnectioBroker HA Cluster" -ScriptBlock {
        $NewCB = [String]::Concat($args[0], ".", $args[2])
        $CBName = $args[1]
        $CBNameFQDN = [String]::Concat($CBName, ".", $args[2])
        
        Import-Module RemoteDesktopServices
        Add-RDServer -Server $NewCB -Role "RDS-CONNECTION-BROKER" -ConnectionBroker $CBNameFQDN
    } -ArgumentList $ConnectionBrokerToAdd, $ConnectionBroker, $DNSRoot
}
function Import-LabHACertificates
{
    param
    (
        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $LabName,

        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $ConnectionBroker
    )

    Import-Module AutomatedLab
    Import-Lab -Name $LabName -NoValidation

    $mypwd = ConvertTo-SecureString -String "Passw0rd!" -Force -AsPlainText
    $rootdcname = Get-LabVM -Role ADDS | Select-Object -First 1

    $PrimaryConnectionBroker = Invoke-LabCommand -ComputerName $ConnectionBroker -ActivityName "Getting the primary Connection Broker Server" -ScriptBlock {
        Import-Module RemoteDesktopServices
        (Get-RDConnectionBrokerHighAvailability).ActiveManagementServer
    } -PassThru -NoDisplay

    Invoke-LabCommand -ComputerName $rootdcname -ActivityName 'Adding the exported certificate to the RDRedirector Role' -ScriptBlock {
        Set-RDCertificate -Role RDRedirector -ImportPath C:\Tools\RDS.pfx -Password $args[0] -ConnectionBroker $args[1] -Force
    } -ArgumentList $mypwd, $PrimaryConnectionBroker

    Invoke-LabCommand -ComputerName $rootdcname -ActivityName 'Adding the exported certificate to the RDPublishing Role' -ScriptBlock {
        Set-RDCertificate -Role RDPublishing -ImportPath C:\Tools\RDS.pfx -Password $args[0] -ConnectionBroker $args[1] -Force
    } -ArgumentList $mypwd, $PrimaryConnectionBroker
}