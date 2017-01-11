$VDSwitchName = "" # DVS Switch Name

$Array = @()

Get-VDSwitch -Name $VDSwitchName | Get-VDPortgroup | Sort-Object Name |
ForEach-Object {

    $Hash = [ordered]@{}
    $Hash.Name = $_.Name
    $Hash.VLAN = $_.VlanConfiguration.VlanId

    $VDSecurityPolicy = $_ | Get-VDSecurityPolicy

    $Hash.AllowPromiscuous =  $VDSecurityPolicy.AllowPromiscuous
    $Hash.MacChanges = $VDSecurityPolicy.MacChanges
    $Hash.ForgedTransmits = $VDSecurityPolicy.ForgedTransmits

    $object = New-Object -TypeName PSObject -Property $Hash

    $Array += $object

}

$Array | Format-Table -AutoSize