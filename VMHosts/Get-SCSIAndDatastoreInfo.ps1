#set EA and final array
$ErrorActionPreference = "Stop"
$Array = @()
$vCenterServer = "" # FQDN of vCenter Server
$PathExportCSV = "C:\~~~\SCSI-Info.csv" # Path for CSV output

#get VMHosts
$VMHosts = Get-VMHost -Server $vCenterServer | sort Name

#create VM RDM Hash Table
$HashRDMs = [ordered]@{}

#get VMs
$VMs = Get-VM -Server $vCenterServer | sort Name

#loop through each VM
foreach($VM in $VMs) {
    
    #get VM hardware device data
    $Devices = $VM.ExtensionData.Config.Hardware.Device 
    foreach ($Device in $Devices) {
        
        #find RDMs
        if ((($Device.GetType()).Name -EQ "VirtualDisk") -and ($Device.Backing.DiskMode -eq "independent_persistent") ) {
            
            #get VMHost from the VM
            $esx = Get-View $VM.VMHost

            #get RDM data using the VM and VMHost 
            $row = "" | select VMName, Label, CanonicalName
            $row.VMName = $VM.Name
            $row.Label = $Device.DeviceInfo.Label
            $row.CanonicalName = ($esx.Config.StorageDevice.ScsiLun | where {$_.Uuid -eq $Device.Backing.LunUuid}).CanonicalName
    
            #populate RDM hashtable, taking into account that there may be more than one entry per key 
            if($HashRDMs[$row.CanonicalName])
            { 
                $HashRDMs[$row.CanonicalName] += ", $($row.VMName)[$($row.Label)]"
            } 
            else 
            {
                $HashRDMs[$row.CanonicalName] = "$($row.VMName)[$($row.Label)]"
            } #end if

            #$report += $row
    
        } #end if
    } #end for
} #end for

#loop through each host
foreach ($VMHost in $VMHosts) {
    
    #get datastores attached to VMHost
    $Datastores = $VMHost | Get-Datastore 
    
    #create hashtable for datastores
    $HashDatastores = [ordered]@{}
    #loop through each datastore
    foreach ($Datastore in $Datastores) {
        #populate hashtable with Diskname and Datastore
        try { $HashDatastores[$Datastore.ExtensionData.Info.Vmfs.Extent.DiskName] = $Datastore.Name }
        catch {}
    } #end for

    #get EsxCli session to VM
    $ESXCli = $VMHost | Get-EsxCli
    $ESXCliDevices = $ESXCli.storage.core.device.list()
    
    $HashPerenniallyReserved = [ordered]@{}
    foreach ($ESXCliDevice in $ESXCliDevices) {
        try { $HashPerenniallyReserved[$ESXCliDevice.Device] = $ESXCliDevice.IsPerenniallyReserved }
        catch {}
    } #end for

    $SCSILuns = $VMHost | Get-ScsiLun

    foreach ($SCSILun in $SCSILuns) {

        $Hash2 = [ordered]@{}
        $Hash2.Host = $VMHost.Name
        $Hash2.Datastore = $HashDatastores[$SCSILun.CanonicalName]
        $Hash2.VMs = $HashRDMs[$SCSILun.CanonicalName]
        $Hash2.Vendor = $SCSILun.Vendor
        $Hash2.PerenniallyReserved = $HashPerenniallyReserved[$SCSILun.CanonicalName]
        $Hash2.CanonicalName = $SCSILun.CanonicalName
        $Hash2.MultipathPolicy = $SCSILun.MultipathPolicy
        $Hash2.LUN = ($SCSILun | Get-ScsiLunPath | select -First 1 Name).Name      
        $Hash2.CapacityGB = $SCSILun.CapacityGB

        $object = New-Object -TypeName PSObject -Property $Hash2

        $Array += $object
    } #end for

} #end for

$Array | sort Host, Datastore, VMs, Vendor, PerenniallyReserved | ft *
$Array | Export-Csv -Path $PathExportCSV -Delimiter "`t"