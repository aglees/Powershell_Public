Clear-Host

$vCenterServer = "" # FQDN of vCenter Server
$VMHosts = Get-VMHost -Server $vCenterServer | sort Name

$Array = @()

ForEach ($VMHost in $VMHosts) {
    
    $ESXCli = Get-EsxCli -VMHost $VMHost
    
    # Debugging Options
    #Write-Host "$($VMHost.Name)`n$("="*($VMHost.Name).Length)" -ForegroundColor Green
    #$ESXCli.storage.core.device.list() | select Device | ft -AutoSize
    
    $StorageDevices = $ESXCli.storage.nmp.device.list() | select Device, PathSelectionPolicy | sort Device

    foreach ($StorageDevice in $StorageDevices) {
        $Hash = [ordered]@{}
        $Hash.Host = $VMHost.Name
        $Hash.Device = $StorageDevice.Device
        $Hash.PSP = $StorageDevice.PathSelectionPolicy
        
        $object = New-Object -TypeName PSObject -Property $Hash  
        
        $Array += $object
    } #end foreach

} #end foreach

$UniqueDevices = $Array | select -Unique device

foreach ($UniqueDevice in $UniqueDevices) {

    Write-Host "$($UniqueDevice.Device)`n$("="*($UniqueDevice.Device).Length)" -ForegroundColor Yellow
    $Array | ? Device -eq $UniqueDevice.Device | select host, PSP | ft -AutoSize

} # end foreach