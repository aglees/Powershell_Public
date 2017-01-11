$VM_List =  @("") # array of VM names

$Snapshot_Name = "" # name of new snapshot
$Snapshot_Desc = "" # description of new snapshot

ForEach ($VM_Name in $VM_List) {
   $VM = Get-VM -Name $VM_Name
   $VM | New-Snapshot -Name $Snapshot_Name -Description $Snapshot_Desc
}