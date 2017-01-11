$VM_List =  @("") # array of VM names

$Snapshot_Name = "" # name of snapshot to revert

ForEach ($VM_Name in $VM_List) {
    
    $VM = Get-VM -Name $VM_Name
    $Snapshot = Get-Snapshot -VM $VM -Name $Snapshot_Name
    Set-VM -VM $VM -Snapshot $Snapshot -Confirm:$false

}