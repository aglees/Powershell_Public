$vCenterServer = "" # FQDN of vCenter Server

$report = @()

$HashRDMs = [ordered]@{}

$VMs = Get-VM -Server $vCenterServer | sort Name

foreach($VM in $VMs) {

    $Devices = $VM.ExtensionData.Config.Hardware.Device 
    foreach ($Device in $Devices) {

        if ((($Device.GetType()).Name -EQ "VirtualDisk") -and ($Device.Backing.DiskMode -eq "independent_persistent") ) {
    
            $esx = Get-View $VM.VMHost

            $row = "" | select VMName, Label, CanonicalName
            $row.VMName = $VM.Name
            $row.Label = $Device.DeviceInfo.Label
            $row.CanonicalName = ($esx.Config.StorageDevice.ScsiLun | where {$_.Uuid -eq $Device.Backing.LunUuid}).CanonicalName
    
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


$HashRDMs
#$report