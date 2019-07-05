function New-LabRDSCollection
{
    [CmdletBinding()]
    param 
    (
        # Parameter help description
        [Parameter(Mandatory, ParameterSetName = 'UserProfileDisk')]
        [Parameter(Mandatory, ParameterSetName = 'IsSessionBasedDesktop')]
        [string]
        $RDSCollectionName,
        
        [Parameter(Mandatory, ParameterSetName = 'UserProfileDisk')]
        [Parameter(Mandatory, ParameterSetName = 'IsSessionBasedDesktop')]
        [string[]]
        $RDSSessionHostServer,

        [Parameter(Mandatory, ParameterSetName = 'UserProfileDisk')]
        [Parameter(Mandatory, ParameterSetName = 'IsSessionBasedDesktop')]
        [string]
        $RDSConnectionBroker,

        [Parameter(Mandatory, ParameterSetName = 'UserProfileDisk')]
        [Parameter(Mandatory, ParameterSetName = 'IsSessionBasedDesktop')]
        [string]
        $RDSDomain,

        [Parameter(Mandatory, ParameterSetName = 'UserProfileDisk')]
        [switch]
        $IsAppCollection,

        [Parameter(Mandatory, ParameterSetName = 'IsSessionBasedDesktop')]
        [switch]
        $IsSessionBasedDesktopCollection,

        [Parameter(Mandatory, ParameterSetName = 'IsSessionBasedDesktop')]
        [string]
        $CollectionADGroupName,

        [Parameter(Mandatory, ParameterSetName = 'UserProfileDisk')]
        [Parameter(Mandatory, ParameterSetName = 'IsSessionBasedDesktop')]
        [switch]
        $UseUserProfileDisks,

        [Parameter(Mandatory, ParameterSetName = 'UserProfileDisk')]
        [Parameter(Mandatory, ParameterSetName = 'IsSessionBasedDesktop')]
        [int]
        $MaxUserProfileDiskSizeGB,

        [Parameter(Mandatory, ParameterSetName = 'UserProfileDisk')]
        [Parameter(Mandatory, ParameterSetName = 'IsSessionBasedDesktop')]
        [string]
        $UserProfileDiskPath
    )
    
    $IsAvailable = Invoke-LabCommand -ComputerName $RDSConnectionBroker -ActivityName "Check if Collection $RDSCollectionName already exists" -ScriptBlock {
        
        Import-Module RemoteDesktopServices

        If (Get-RDSessionCollection -CollectionName "$($args[0])" -ErrorAction SilentlyContinue)
        {
            return $true
        }
        else
        {
            return $false
        }

    } -ArgumentList $RDSCollectionName -PassThru

    if ($IsAvailable -eq $false)
    {
        Invoke-LabCommand -ComputerName $RDSConnectionBroker -ActivityName "Adding RDS Collection $RDSCollectionName to RDS Deployment with the Session Host Servers you provided." -ScriptBlock {
            Import-Module RemoteDesktopServices

            $SHArray = New-Object -TypeName System.Collections.ArrayList

            foreach ($RDSSessioHost in $args[1])
            {
                $SHNameNew = [String]::Concat($RDSSessioHost, '.', $args[2])
                $null = $SHArray.Add($SHNameNew)
            }

            New-RDSessionCollection -CollectionName ("{0}" -f $args[0]) -SessionHost $SHArray
        } -ArgumentList $RDSCollectionName, $RDSSessionHostServer, $RDSDomain

        switch ($PSCmdlet.ParameterSetName)
        {
            'IsSessionBasedDesktop'
            {
                if ($PSBoundParameters.ContainsKey('UseUserProfileDisks'))
                {
                    $setLabRDSCollectionSplat = @{
                        IsSessionBasedDesktopCollection = $true
                        MaxUserProfileDiskSizeGB        = $MaxUserProfileDiskSizeGB
                        UserProfileDiskPath             = $UserProfileDiskPath
                        CollectionADGroupName           = $CollectionADGroupName
                        UseUserProfileDisks             = $true
                        RDSConnectionBroker             = $RDSConnectionBroker
                        RDSCollectionName               = $RDSCollectionName
                    }
                    Set-LabRDSCollection @setLabRDSCollectionSplat
                }
                else
                {
                    $setLabRDSCollectionSplat = @{
                        RDSCollectionName               = $RDSCollectionName
                        CollectionADGroupName           = $CollectionADGroupName
                        RDSConnectionBroker             = $RDSConnectionBroker
                        IsSessionBasedDesktopCollection = $true
                    }
                    Set-LabRDSCollection @setLabRDSCollectionSplat   
                }
                
            }

            'UserProfileDisk'
            {
                $setLabRDSCollectionSplat = @{
                    MaxUserProfileDiskSizeGB = $MaxUserProfileDiskSizeGB
                    UserProfileDiskPath      = $UserProfileDiskPath
                    UseUserProfileDisks      = $true
                    RDSConnectionBroker      = $RDSConnectionBroker
                    RDSCollectionName        = $RDSCollectionName
                    IsAppCollection          = $true
                }
                Set-LabRDSCollection @setLabRDSCollectionSplat
            }
        }        
    }
    else
    {
        Write-ScreenInfo -Message "Collection $RDSCollectionName already exists."
    }
}

function Set-LabRDSCollection
{
    [CmdletBinding()]
    param 
    (
        # Parameter help description
        [Parameter(Mandatory, ParameterSetName = 'UserProfileDisk')]
        [Parameter(Mandatory, ParameterSetName = 'IsSessionBasedDesktop')]
        [string]
        $RDSCollectionName,
        
        [Parameter(Mandatory, ParameterSetName = 'UserProfileDisk')]
        [Parameter(Mandatory, ParameterSetName = 'IsSessionBasedDesktop')]
        [string]
        $RDSConnectionBroker,

        [Parameter(Mandatory, ParameterSetName = 'UserProfileDisk')]
        [switch]
        $IsAppCollection,

        [Parameter(Mandatory, ParameterSetName = 'IsSessionBasedDesktop')]
        [switch]
        $IsSessionBasedDesktopCollection,

        [Parameter(Mandatory, ParameterSetName = 'IsSessionBasedDesktop')]
        [string]
        $CollectionADGroupName,

        [Parameter(Mandatory, ParameterSetName = 'UserProfileDisk')]
        [Parameter(Mandatory, ParameterSetName = 'IsSessionBasedDesktop')]
        [switch]
        $UseUserProfileDisks,

        [Parameter(Mandatory, ParameterSetName = 'UserProfileDisk')]
        [Parameter(Mandatory, ParameterSetName = 'IsSessionBasedDesktop')]
        [int]
        $MaxUserProfileDiskSizeGB,

        [Parameter(Mandatory, ParameterSetName = 'UserProfileDisk')]
        [Parameter(Mandatory, ParameterSetName = 'IsSessionBasedDesktop')]
        [string]
        $UserProfileDiskPath
    )

    switch ($PSCmdlet.ParameterSetName)
    {
        'IsSessionBasedDesktop'
        {
            if ($PSBoundParameters.ContainsKey('UseUserProfileDisks'))
            {
                $restult_Groupexists = Invoke-LabCommand -ComputerName $RDSConnectionBroker -ActivityName "Check if Group $CollectionADGroupName exists" -ScriptBlock {
                    try
                    {
                        $null = Get-ADGroup -Identity $args[0]
                        return $true
                    }
                    catch
                    {
                        return $false
                    }
                } -ArgumentList $CollectionADGroupName
                
                if ($restult_Groupexists -eq $false)
                {
                    Invoke-LabCommand -ComputerName $RDSConnectionBroker -ActivityName "Creating Domain Local Group $CollectionADGroupName for Collection $RDSCollectionName" -ScriptBlock {
                        Import-Module ActiveDirectory
                        $RDSGroupsDN = (Get-ADOrganizationalUnit -Filter "Name -eq 'RDSGroups'").DistinguishedName
                        try
                        {
                            Get-ADGroup -Identity $args[0]
                        }
                        catch
                        {
                            New-ADGroup -Name $args[0] -SamAccountName $args[0] -GroupCategory Security -GroupScope DomainLocal -DisplayName $args[0] -Path $RDSGroupsDN    
                        }                    
                    } -ArgumentList $CollectionADGroupName    
                }

                Invoke-LabCommand -ComputerName $RDSConnectionBroker -ActivityName "Set the Usergroup $CollectionADGroupName on Colletion $RDSCollectionName" -ScriptBlock {
                    Import-Module RemoteDesktopServices
                    Set-RDSessionCollectionConfiguration -CollectionName $args[0] -UserGroup $args[1]
                } -ArgumentList $RDSCollectionName, $CollectionADGroupName

                Invoke-LabCommand -ComputerName $RDSConnectionBroker -ActivityName "Enable UserProfileDisks on Collection $RDSCollectionName." -ScriptBlock {
                    Import-Module RemoteDesktopServices
                    Set-RDSessionCollectionConfiguration -CollectionName $args[0] -EnableUserProfileDisk -DiskPath $args[1] -MaxUserProfileDiskSizeGB $args[2]
                } -ArgumentList $RDSCollectionName, $UserProfileDiskPath, $MaxUserProfileDiskSizeGB                
            }   
        }

        'UserProfileDisk'
        {
            Invoke-LabCommand -ComputerName $RDSConnectionBroker -ActivityName "Set the Usergroup DL_RDSUsers on Colletion $RDSCollectionName" -ScriptBlock {
                Import-Module RemoteDesktopServices
                Set-RDSessionCollectionConfiguration -CollectionName $args[0] -UserGroup "DL_RDSUsers"
            } -ArgumentList $RDSCollectionName
            
            Invoke-LabCommand -ComputerName $RDSConnectionBroker -ActivityName "Enable UserProfileDisks on Collection $RDSCollectionName." -ScriptBlock {
                Import-Module RemoteDesktopServices
                Set-RDSessionCollectionConfiguration -CollectionName $args[0] -EnableUserProfileDisk -DiskPath $args[1] -MaxUserProfileDiskSizeGB $args[2]
            } -ArgumentList $RDSCollectionName, $UserProfileDiskPath, $MaxUserProfileDiskSizeGB
        }
    }
}