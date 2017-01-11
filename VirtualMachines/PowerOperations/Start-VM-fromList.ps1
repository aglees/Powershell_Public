$VM_List =  @("") # array of VM names

ForEach ($VM_Name in $VM_List) {
    
    Get-VM -Name $VM_Name | Start-VM
    #sleep -Seconds 30

}