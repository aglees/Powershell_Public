$ESXiHost = "" #FQDN of ESXi VMHost

$View = Get-View -ViewType "VirtualMachine" <# -Property Name #> `
 -Filter @{"Runtime.PowerState"="PoweredOn"} `
 -SearchRoot $(Get-View -ViewType "HostSystem" `
 -Filter @{"Name"=$ESXiHost} -Property Name).MoRef

ForEach ($VM in $View) {

$CDDVD = $VM.Config.Hardware.Device.DeviceInfo | 
? { (($_.Label -like "*CD/DVD*") -and ($_.Summary -like "*iso")) }

If ( $CDDVD.Summary ) {
    Write-Host "$($VM.Name) ISO present" -ForegroundColor Red
} Else {
    Write-Host "$($VM.Name) ISO not present"
}

}