$Array = @()

$PortGroups = Get-VDSwitch | Get-VDPortgroup 
foreach($PortGroup in $PortGroups) 
{

    $Hash = [ordered]@{}
    $Hash.dvSwitch = $PortGroup.VDSwitch
    $Hash.Name = $PortGroup.Name
    $Hash.VLAN = $PortGroup.vlanconfiguration.vlanid

    $object = New-Object -TypeName PSObject -Property $Hash

    $Array += $object
}

$Array | Format-Table -AutoSize