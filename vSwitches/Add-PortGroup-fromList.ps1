$CSVPath = "C:\~~~~\VMNetworks-For-Import.csv"
$VDSwitchName = ""

$Data_To_Import = Import-Csv -Path $CSVPath

foreach ($item in $Data_To_Import) {

    $PortGroup_Name = $item.Name
    $PortGroup_VlanId = $item.VLanId

    Write-Host "PortGroup Name: $PortGroup_Name `tPortGroup VlanId:  $PortGroup_VlanId"

    New-VDPortgroup -VDSwitch $VDSwitchName -Name $PortGroup_Name -VlanId $PortGroup_VlanId

} 