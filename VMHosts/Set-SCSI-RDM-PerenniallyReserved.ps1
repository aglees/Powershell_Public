$vCenterServer = "" # FQDN of vCenter Server

$VMHosts = Get-VMHost -Server $vCenterServer

# replace these with your device IDs to be set as perennially reserved
$RDMS = ("naa.60002ac0000000000000da5a00014e4a", `
        "naa.60002ac0000000000000da6100014e4a", `
        "naa.60002ac0000000000000da6200014e4a", `
        "naa.60002ac0000000000000da6300014e4a", `
        "naa.60002ac0000000000100211400014e4a")

foreach ($VMHost in $VMHosts) {

$VMHost | Get-ScsiLun | ? CanonicalName -In $RDMS | ft -AutoSize

$ESXCli = $VMHost | Get-EsxCli 

    foreach ($RDM in $RDMs) {

        $ESXCli.storage.core.device.setconfig($false, $RDM, $true)

    }

}