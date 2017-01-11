. 'C:\Users\admin_AGleeson\Documents\WindowsPowerShell\Functions\Get-FolderAdvanced.ps1'

<#
.Synopsis
   Test xMoveInfo against destination VMHost
.NOTES
   File Name  : Test-xMove-VMInfo.ps1
   Author     : Andrew Gleeson - @aglees
   Version    : 1.0
.DESCRIPTION
   Take object from Get-xMove-VMInfo, and tests against the destination environment. 
   Looks at datastores, networks and folders.
.EXAMPLE
    # Get xMove information
    $xMoveInfo = Get-xMove-VMInfo -FolderTarget $sourceFolder `
                    -PortGroupMappingPath $portMap `
                    -FolderMappingPath $folderMap `
                    -Datacenter $sourceDatacenter `
                    -Recursive:$souceGetSubFolderVMs `
                    -Conn $sourceVCConn

    # Test xMove information versus destination VM host
    $boolean_TestxMoveInfo = Test-xMove-VMInfo -xMoveVmInfo $xMoveInfo `
                                -DestVmHostName $destVmHostName `
                                -DestSwitchName $destSwitchName `
                                -DestDatacenter $destDatacenter `
                                -DestVcConn $destVCConn
#>
function Test-xMove-VMInfo
{
    [OutputType([boolean])]
    Param
    (
        # Param1 xMoveVmInfo << the data being checked >>
        [Parameter(Mandatory=$true,Position=0)]
        [PSObject]$xMoveVmInfo,

        # Param2 DestVmHostName << the VM host used for checking >>
        [Parameter(Mandatory=$true)]
        [string]$DestVmHostName,

        # Param3 DestSwitchname << the destination switch being checked >>
        [Parameter(Mandatory=$true)]
        [string]$DestSwitchName,

        # Param5 DestDatacenter << the datacenter holding the VM folders >>
        [Parameter(Mandatory=$true)]
        [string]$DestDatacenter,

        # Param5 DestVcConn << the vCenter connection >>
        [Parameter(Mandatory=$true)]
        [VMware.VimAutomation.ViCore.Impl.V1.VIServerImpl]$DestVcConn
    )

    Begin
    {
        $strHeader = "Checking xMove virtual machine information"
        Write-Host "`n$strHeader`n$("="*$strHeader.length)`n" -ForegroundColor Yellow
    } #end Begin
    
    Process
    {
        # check arrayInfo is present, and has data
        if((!$xMoveVmInfo) -or ($xMoveVmInfo.Length -eq 0)) { # no variable, or no data in variable. Display error and break.
            Write-Host "No migration information present. Please use [Get-xMove-VMInfo.ps1] with the correct VM filter" -ForegroundColor Red
            break; 
        }
        else { # test passed
            $strSubHeader = "Items to be tested"
            Write-Host "`n$strSubHeader`n$("="*$strSubHeader.Length)" -ForegroundColor Yellow
            $xMoveVmInfo | ft -AutoSize | Out-Host
        } #end if check arrayInfo

        # set errorcount
        $errorcount = 0

        # check datastores on destination
        foreach($Info in $xMoveVmInfo) {
    
            try { # try to get destination VMHost and datastores
                    $VMHost = Get-VMHost -Name $DestVmHostName -Server $DestVcConn
                    $Dummy = Get-Datastore -VMHost $VMHost -Name $info.Datastores -Server $destVCConn -ErrorAction Stop }
            catch { # no datastores found
                Write-Host "Destination datastore $($Info.Datastores) does not exist." -ForegroundColor Red; 
                $errorcount++
            }
        } #end foreach check destination datastores

        # check networks on destination
        foreach($Info in $xMoveVmInfo){ # check info per vm
    
            $portGroups = $Info.Networks -split ","

            foreach($portGroup in $portGroups){ # iterate and check portgroups
                
                try { # try to get destination portgroup
                    $Dummy = Get-VDPortgroup -VDSwitch $DestSwitchName -Name $portGroup -Server $DestVcConn -ErrorAction Stop
                }
                catch { # no port groups found
                    Write-Host "Portgroup [$portGroup] not found on destination dvSwitch." -ForegroundColor Red
                    $errorcount++
                } #end try-catch
            
            } #end foreach porgroup 
        
        } #end foreach check destination networks 
    
        # check destination folder exists
        foreach($Info in $xMoveVmInfo){ # check folders per vm
            
            $Folder = $Info.Folder

            try { # use [Get-Folder-Advanced] to get the destination folder
                $Dummy = Get-Folder-Advanced -MyFolder $Folder -Datacenter $DestDatacenter -Conn $DestVcConn
            }
            catch { # error getting destination folder
                Write-Host "Folder [$Folder] not found at destination." -ForegroundColor Red
                $errorcount++
            } #end try-catch

            if($Dummy.length -gt 1){ # error as more than one destination folder was returned
               Write-Host "More than one destination folder returned" -ForegroundColor Red
               $Dummy | ft Name, Parent -AutoSize | Out-Host
               $errorcount++
            } #end if folder count
            
        } #end foreach folder map
    
    } #end Process
    
    End
    {
    
        # check error count and return false if any
        if ($errorcount -gt 0) { # errors have been detected
            Write-Host "Remediate all errors and try again." -ForegroundColor Red
            return $false 
        } 
        else { # if no errors
            return $true
        } #end if      
    
    } #end End

} #end Function [Test-xMove-VMInfo]