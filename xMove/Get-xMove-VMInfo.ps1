. 'C:\Users\admin_AGleeson\Documents\WindowsPowerShell\Functions\Get-FolderAdvanced.ps1'

<#
.Synopsis
   Get xVCvMotion information for multiple VMs based on a given VM folder. 
   For use with xMove cross vCenter vMotion scripts
.NOTES
   File Name  : Get-xMove-VMInfo.ps1
   Author     : Andrew Gleeson - @aglees
   Version    : 1.0
.DESCRIPTION
   Long description
.EXAMPLE
   # Get xMove information
   $xMoveInfo = Get-xMove-VMInfo -FolderTarget $sourceFolder `
                    -PortGroupMappingPath $portMap `
                    -FolderMappingPath $folderMap `
                    -Datacenter $sourceDatacenter `
                    -Recursive:$souceGetSubFolderVMs `
                    -Conn $sourceVCConn
#>
function Get-xMove-VMInfo
{
    [OutputType([PSObject])]
    Param
    (
        # Param1 Folder target for [Get-FolderAdvanced] to consume
        [string]$FolderTarget="",

        # Param2 Path to portgroup mapping file
        [string]$PortGroupMappingPath="C:\~~~~\PortGroupMappings.txt",

        # Param3 Path to folder mapping file
        [string]$FolderMappingPath="C:\~~~~\FolderMappings.txt",

        # Param4 Connection to vCenter server
        [VMware.VimAutomation.ViCore.Impl.V1.VIServerImpl]$Conn,

        # Param5 Datacenter
        [string]$Datacenter="", # VMware Datacenter Name

        #Param6 Recursively get child VMs
        [boolean]$Recursive=$false
    )

    Begin
    {
        $portMap = Import-Csv -Path $PortGroupMappingPath -Delimiter ","
        $folderMap = Import-Csv -Path $FolderMappingPath -Delimiter ","
                
        # get input folder using [Get-Folder-Advanced] function
        $Folder = Get-Folder-Advanced -MyFolder $FolderTarget -Datacenter $Datacenter -Conn $Conn
        
        # get VMs from folder, and alternatively get VMs from child folders
        if(!$Recursive) {
           $VMs = $Folder  | Get-VM | ? Folder -eq $Folder | sort Name
        }
        else {
           $VMs = $Folder  | Get-VM | sort Name
        }

        # reset output array
        $arrayInfo = @()

        # write header information to screen
        $strHeader = "Gathering xMove-VM Virtual Machine Information"
        Write-Host "`n$strHeader`n$("="*$strHeader.length)" -ForegroundColor Yellow   
    
    } #end Begin
    
    Process
    {
        # loop through each VM
        foreach ($VM in $VMs) {
            
            # blank variables for hash, networks and datastores per VM
            $hash = [ordered]@{}
            $strNetworks = ""
            $strDatastores = ""

            #get folder per VM
            $strFolder = ($FolderMap | ? sourceFolder -eq $VM.Folder.Name).destFolder

            #get datastores per VM
            $Datastores = $VM | Get-Datastore
    
            # get NICs per VM
            $NICs = $VM | Get-NetworkAdapter    
    
            # write VM name to screen
            Write-Host "$($Vm.Name)" -NoNewline

            # loop through each NIC per VM
            foreach ($NIC in $NICs) {
    
                # match network against portmap, and add to output string
                $strNetworks += $($portMap | ? SourceNet -eq $NIC.NetworkName).destNet + ","
    
            } #end foreach NICs
    
            #remove trailing ',' from output string
            $strNetworks = $strNetworks -replace ".$"
    
            # loop through each datastore per VM
            foreach ($Datastore in $Datastores) {
    
                # match network against portmap, and add to output string
                $strDatastores += $Datastore.Name + ","
    
            } #end foreach Datastores
    
            #remove trailing ',' from string
            $strDatastores = $strDatastores -replace ".$"

            # output information
            $hash.VM = $VM.Name
            $hash.Networks = $strNetworks
            $hash.Datastores = $strDatastores
            $hash.Folder = $strFolder
    
            # add info to output array
            $object = New-Object -TypeName PSObject -Property $hash
            $arrayInfo += $object

            # write to screen
            Write-Host "`t[OK]" -ForegroundColor Green

         } #end foreach VM
    
    } #end Process
    
    End
    {
        # write output information to screen
        Write-Host "`nOutput`n======" -ForegroundColor Yellow
        Write-Host "The object [`$arrayInfo] has been populated for use in this PowerCli session."
        $arrayInfo | ft -AutoSize | Out-Host  

        # return output array
        Return $arrayInfo
    
    } #end End

}# end Function [Get-xMove-VMInfo]