$vCenterServer = "" # FQDN of vCenter Server

$array = @()

$VDSwitch = Get-VDSwitch -Server $vCenterServer

$VDPortGroups = Get-VDPortgroup -VDSwitch $VDSwitch

foreach($VDPortGroup in $VDPortGroups) {

    
    $Hash = [ordered]@{}
    $Hash.Name = $VDPortGroup.Name
    $Hash.VlanID = $VDPortGroup.VlanConfiguration.VlanId
    $Hash.VlanType = $VDPortGroup.VlanConfiguration.VlanType
    $Hash.PrimaryVlanId = $VDPortGroup.VlanConfiguration.PrimaryVlanId
    $Hash.PrivateVlanType = $VDPortGroup.VlanConfiguration.PrivateVlanType
    $Hash.SecondaryVlanId = $VDPortGroup.VlanConfiguration.SecondaryVlanId
    
    $object = New-Object -TypeName PSObject -Property $Hash

    $array += $object

}

$array | sort Name | ft * -AutoSize