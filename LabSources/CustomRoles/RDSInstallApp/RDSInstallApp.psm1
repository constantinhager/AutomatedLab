function Publish-LabRDSApp
{
    [CmdletBinding()]
    param 
    (
        # The RDS App Name (only for Logging)
        [Parameter(Mandatory)]
        [ValidateScript(
            {               
                if ($_ -match "[$([Regex]::Escape('/\[:;|=,+*?<>') + '\]' + '\"')]")
                {
                    return $false
                }
                else
                {
                    return $true
                }
            }
        )]
        [String]
        $RDSAppName,
        
        [Parameter(Mandatory)]
        [string]
        $RDSAppDiscoveryName,

        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $RDSCollectionName,

        # The path where the app is
        [Parameter()]
        [string]
        $RDSAppPath = (Join-Path -Path (Get-LabSourcesLocation) -ChildPath "SoftwarePackages"),

        # the name of the executable
        [Parameter(Mandatory)]
        [string]
        $RDSAppExecutableName,

        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $RDSSetUpExecutableName,

        # install arguments of the app
        [Parameter(Mandatory)]
        [string]
        $RDSAppPathArguments,

        # install arguments of the app
        [Parameter()]
        [string]
        $RDSAppDownloadUri,

        [Parameter(Mandatory)]
        [string[]]
        $RDSSessionHostServer,

        # Parameter help description
        [Parameter(Mandatory)]
        [string[]]
        $ADUser,

        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $LabPath
    )

    Import-Lab -Path $LabPath -NoValidation
    $rootdcname = Get-LabVM -Role RootDC | Select-Object -First 1 -ExpandProperty Name
    #region Install Software

    Write-ScreenInfo -Message "Check if $RDSSetUpExecutableName is in $RDSAppPath"
    
    $AppPath = (Join-Path -Path $RDSAppPath -ChildPath $RDSSetUpExecutableName)
    
    if (Test-Path -Path $AppPath)
    {
        foreach ($RDSSHS in $RDSSessionHostServer)
        {            
            Write-ScreenInfo -Message "Install $RDSAppName on Session Host Server $RDSSessionHostServer"
            Install-LabSoftwarePackage -ComputerName $RDSSHS -Path $AppPath -CommandLine $RDSAppPathArguments                
        }        
    }
    else
    {
        Write-ScreenInfo -Message "The file $RDSSetUpExecutableName in path $RDSAppPath is not available. Check if you provided a Download Uri."
        if ($PSBoundParameters.ContainsKey('RDSAppDownloadUri'))
        {
            Write-ScreenInfo -Message "Downloading $RDSAppName from the following URL: $RDSAppDownloadUri"
            $AppObject = Get-LabInternetFile -Uri $RDSAppDownloadUri -Path $RDSAppPath -PassThru

            foreach ($RDSSHS in $RDSSessionHostServer)
            {                
                Install-LabSoftwarePackage -ComputerName $RDSSHS -Path $AppObject.FullName -CommandLine $RDSAppPathArguments       
            }
        }
        else
        {
            Write-Error "You do not provide a Download Uri. Please use the RDSAppDownloadUri parameter."
        }
    }
    #endregion Install Software
    
    #region create AD Group and add it to DL_RDSUsers
    $RDSSetupPath = Join-Path -Path (Get-LabSourcesLocation) -ChildPath "\CustomRoles\RDSSetup"
    Import-Module (Join-Path -Path $RDSSetupPath -ChildPath SetupHelper.psm1)
    $module = Get-Command -Module SetupHelper

    foreach ($RDSSHS in $RDSSessionHostServer)
    {
        Invoke-LabCommand -ComputerName $RDSSHS -ActivityName "Create Domain Local Group for App $RDSAppName" -ScriptBlock {
            Import-Module ActiveDirectory
            $DomainInfo = Get-DomainInformation
            $DomainDN = $DomainInfo.distinguishedName
            $OuNameDN = [String]::Concat("OU=RDSGroups,", "OU=RDS,", $DomainDN)
            $Group = [String]::Concat('DL_', $args[0])
            try
            {
                $null = Get-ADGroup -Identity $Group
            }
            catch
            {
                New-ADGroup -Name $Group -SamAccountName $Group -GroupCategory Security -GroupScope DomainLocal -DisplayName $Group -Path $OuNameDN    
            }            
        } -Function $module -ArgumentList $RDSAppName -PassThru

        Invoke-LabCommand -ComputerName $RDSSHS -ActivityName "Add DL_$RDSAppName to DL_RDSUsers." -ScriptBlock {
            Import-Module ActiveDirectory
            $Group = [String]::Concat('DL_', $args[0])
            $RDSUserMembers = Get-ADGroupMember -Identity "DL_RDSUsers" | Select-Object -ExpandProperty name
            $found = $false
            foreach ($RDSUserMember in $RDSUserMembers)
            {
                if ($RDSUserMember -eq $Group)
                {
                    $found = $true
                }
            }

            if ($found)
            {
            }
            else
            {
                Add-ADGroupMember -Members $Group -Identity 'DL_RDSUsers'    
            }
            
        } -NoDisplay -ArgumentList $RDSAppName
    }
    #endregion create AD Group and add it to DL_RDSUsers

    #TODO: region Add User to the appropriate Group

    #endregion Add User to the appropriate Group

    #region Publish RDS App

    $AllCBServers = Invoke-LabCommand -ComputerName $rootdcname -ActivityName 'Get All Connection Broker Servers.' -ScriptBlock {
        Get-RDSADComputer -OUName "RDSCB"
    } -Function $module -PassThru -NoDisplay

    $firstcb = $AllCBServers | Select-Object -First 1
    $firstsh = $RDSSessionHostServer | Select-Object -First 1

    $InstallLocation = Invoke-LabCommand -ComputerName $firstsh -ActivityName 'Get the install locaction of the app from the sessionhost server' -ScriptBlock {
        $AppName = $args[0]
        $InstallLocation = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" |
            ForEach-Object {Get-ItemProperty $_.PSPath} | Where-Object {$_.DisplayName -like "*$AppName*"} |
            Select-Object -ExpandProperty InstallLocation
        
        if ([String]::IsNullOrWhiteSpace($InstallLocation))
        {
            $InstallLocation = Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" |
                ForEach-Object {Get-ItemProperty $_.PSPath} | Where-Object {$_.DisplayName -like "*$AppName*"} |
                Select-Object -ExpandProperty InstallLocation
            
            if ([String]::IsNullOrWhiteSpace($InstallLocation))
            {
                Write-Error -Message "InstallLocation Not found."        
            }
        }

        $return_InstallLocation = $InstallLocation | Select-Object -First 1
        return $return_InstallLocation
    } -PassThru -ArgumentList $RDSAppDiscoveryName

    $InstallLocation = $InstallLocation | Select-Object -First 1

    Invoke-LabCommand -ComputerName $firstcb.ComputerName -ActivityName 'Publish the App to the current RDS Deployment' -ScriptBlock {
        Import-Module RemoteDesktopServices
        $Group = [String]::Concat('DL_', $args[1])
        $RDSCollection = "$($args[2])"
        $DisplayName = "$($args[1])"
        $FilePath = "$($args[0])"
        $Exe = "$($args[3])"
        $FullPath = Join-Path -Path $FilePath -ChildPath $Exe
        New-RDRemoteApp -CollectionName $RDSCollection -DisplayName $DisplayName -FilePath $FullPath -UserGroups $Group
    } -ArgumentList $InstallLocation, $RDSAppName, $RDSCollectionName, $RDSAppExecutableName
    #endregion Publish RDS App
}