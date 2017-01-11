
$VM_List =  @("") # array of VM names

ForEach ($VM_Name in $VM_List) {
    
    Get-VM -Name $VM_Name | Restart-VMGuest -Confirm:$false
    #sleep -Seconds 30 # optional sleep between iterations

}