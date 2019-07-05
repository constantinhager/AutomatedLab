#region ServerManager Helper
function Get-ServerListPath
{
    $ServerListPath = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\ServerManager\ServerList.xml"
    return $ServerListPath
}

function Test-IfServerListExist
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $ServerListPath
    )

    if (Test-Path -Path $ServerListPath)
    {
        return $true
    }
    else
    {
        return $false
    }
}
function Get-ServerListXMLFile
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $ServerListFile
    )

    $ServerListContent = [xml](Get-Content -Path $ServerListFile)
    return $ServerListContent
}
function Get-AllServersInServerListFile
{
    $return_ServerListPath = Get-ServerListXMLFile -ServerListFile (Get-ServerListPath)
    $AllXMLServers = $return_ServerListPath.ServerList.ServerInfo.name
    return $AllXMLServers
}
function Find-IfServerIsInServerListFile
{
    param
    (
        [Parameter(Mandatory)]
        [string[]]
        $AllXMLServers,

        [Parameter(Mandatory)]
        [string[]]
        $AllRDSComputers
    )

    $returnarray = New-Object -TypeName System.Collections.ArrayList

    foreach ($XMLServer in $AllXMLServers)
    {
        foreach ($RDSServer in $AllRDSComputers)
        {
            if ($RDSServer -eq $XMLServer)
            {
                $row = [PSCustomObject]@{Status = $true; RDSServer = $RDSServer}
                $null = $returnarray.Add($row)
            }
            else
            {
                $row = [PSCustomObject]@{Status = $false; RDSServer = $RDSServer}
                $null = $returnarray.Add($row)
            }
        }
    }
    return $returnarray
}
function Add-XMLEntryToServerListFile
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $RDSServer
    )
    
    $ServerListContent = Get-ServerListXMLFile -ServerListFile (Get-ServerListPath)

    $NewServer = @($ServerListContent.ServerList.ServerInfo)[0].Clone()
    $NewServer.Name = "$RDSServer"
    $NewServer.LastUpdateTime = '0001-01-01T00:00:00'
    $NewServer.status = '2'
    
    $null = $ServerListContent.ServerList.AppendChild($NewServer)
    return $ServerListContent
}
function Add-ServerListEntry
{
    $ServerListPath = Get-ServerListPath
    # Make a duplicate of the ServerList.xml
    $ServerList_NewPath = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\ServerManager\ServerList1.xml"
    if (Test-IfServerListExist -ServerListPath $ServerList_NewPath)
    {
        Write-Output 'File already exists. No action needed.'
        $ServerListFile = Get-Item -Path (Get-ServerListPath)
    }
    else
    {
        Copy-Item -Path $ServerListPath -Destination $ServerList_NewPath -Force
        $ServerListFile = Get-Item -Path (Get-ServerListPath)
    }

    # Import the XML File
    #$return_GetServerListXMLFile = Get-ServerListXMLFile -ServerListFile $ServerListFile
    
    $return_AllXMLServers = Get-AllServersInServerListFile
    $return_AllRDSADPCs = Get-AllRDSComputers

    # Create a New ServerElement for each RDS Server
    $return_FindIfServerIsInServerListFile = Find-IfServerIsInServerListFile -AllXMLServers $return_AllXMLServers -AllRDSComputers $return_AllRDSADPCs.ComputerName 

    if ($return_FindIfServerIsInServerListFile.Where{$_.Status -eq $true})
    {
        Write-Output 'Entry is already in ServerList.xml.'
    }
    else
    {
        Write-Output 'Entry is not in ServerList.xml. Adding it.'
        for ($i = 0; $i -lt $return_FindIfServerIsInServerListFile.Count; $i++)
        {
            $return_AddXMLEntryToServerListFile = Add-XMLEntryToServerListFile -RDSServer $return_FindIfServerIsInServerListFile[$i].RDSServer
            $null = $return_AddXMLEntryToServerListFile.Save($ServerListFile.FullName)
        }        
    }
}
function New-ServerListFile
{
    # Starting ServerManager
    Start-Process -FilePath "$env:windir\System32\ServerManager.exe"
    Start-Sleep -Seconds 10
    # Stop ServerManager gracefully to create the xml File
    $null = Get-Process -Name ServerManager | ForEach-Object {$_.CloseMainWindow()}
    Start-Sleep -Seconds 10

    $ServerListPath = Get-ServerListPath
    # Make a duplicate of the ServerList.xml
    $ServerList_NewPath = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\ServerManager\ServerList1.xml"
    if (Test-Path -Path $ServerList_NewPath)
    {
        Write-Output 'File already exists. No action needed.'
    }
    else
    {
        Copy-Item -Path $ServerListPath -Destination $ServerList_NewPath -Force
    }
}
#endregion

#region AD
function Get-DomainInformation
{
    $domaininfo = [adsi]""
    return $domaininfo
}

function Get-RDSADComputer
{
    param
    (
        [Parameter(Mandatory)]
        [String]
        $OuName
    )
    
    $AllOUComputers = New-Object -TypeName System.Collections.ArrayList
    
    $DomainInformation = Get-DomainInformation
    $DomainDN = $DomainInformation.distinguishedName
    $OuNameDN = [String]::Concat("OU=$OuName,", "OU=RDS,", $DomainDN)
    $Computers = (Get-ADComputer -Searchbase $OUNameDN -Filter * -Properties *)

    foreach ($Computer in $Computers)
    {
        $row = [PSCustomObject]@{
            DNSHostName  = $Computer.DNSHostName
            ComputerName = $Computer.Name
            IPAddress    = $Computer.IPv4Address
            OS           = $Computer.OperatingSystem
        }
        $null = $AllOUComputers.Add($row)
    }

    return $AllOUComputers
}

function Get-AllRDSComputers
{
    $AllOUComputers = New-Object -TypeName System.Collections.ArrayList
    
    $DomainInformation = Get-DomainInformation
    $DomainDN = $DomainInformation.distinguishedName
    $OuNameDN = [String]::Concat("OU=RDS,", $DomainDN)
    $Computers = (Get-ADComputer -Searchbase $OUNameDN -Filter *).DNSHostName

    foreach ($Computer in $Computers)
    {
        $row = [PSCustomObject]@{
            ComputerName = $Computer
        }
        $null = $AllOUComputers.Add($row)
    }

    return $AllOUComputers
}
#endregion

#region RDS
function Get-RDSDeployment
{
    param
    (
        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $ConnectionBrokerHA,

        # Parameter help description
        [Parameter(Mandatory=$false)]
        [string]
        $DNSHostName
    )

    Import-Module RemoteDesktop
    
    if($ConnectionBrokerHA -eq 'Yes')
    {
        $result = (Get-RDConnectionBrokerHighAvailability -ConnectionBroker $DNSHostName -Erroraction SilentlyContinue).ActiveManagementServer
    }
    else
    {
        $result = Get-RDServer
    }
    
    if ($result)
    {
        return $true        
    }
    else
    {
        return $false
    }
}
#endregion