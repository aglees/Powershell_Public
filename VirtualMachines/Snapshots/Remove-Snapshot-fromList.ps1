$VM_List =  @("") # array of VM names

$Snapshot_Name = "" # name of snapshot to remove

ForEach ($VM_Name in $VM_List) {
    
    $Snapshot = $VM | Get-Snapshot -Name $Snapshot_Name
    Remove-Snapshot -Snapshot $Snapshot -Confirm:$false -RemoveChildren
}

