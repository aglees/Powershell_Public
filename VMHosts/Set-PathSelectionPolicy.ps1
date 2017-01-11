$vCenterServer = "" # FQDN of vCenter Server

$PSP = "RoundRobin","Fixed"

# add your SCSI device IDs to exclude
$ExcludeDevice = "naa.60002ac0000000000101301500014e4a","naa.60002ac0000000000101993500014e4a"

#$VMHost4 = Get-VMHost -Server $vCenterServer | ? Name -eq "sample.esxi.fqdn"
$VMHosts = Get-VMHost -Server $vCenterServer | sort Name

foreach ($VMHost in $VMHosts) {
    
    Write-Host "$($VMHost.Name)`n$("="*($VMHost.Name).Length)" -ForegroundColor Green
    $VMHost | Get-ScsiLun | ? { ($_.MultipathPolicy -NotIn $PSP) -and ( $_.CanonicalName -NotIn $ExcludeDevice) } | ft -AutoSize
    $VMHost | Get-ScsiLun | ? { ($_.MultipathPolicy -NotIn $PSP) -and ( $_.CanonicalName -NotIn $ExcludeDevice) } | Set-ScsiLun -MultipathPolicy RoundRobin

}

# Old debug code
<#

#$VMHost4 | Get-ScsiLun | ? MultipathPolicy -NotIn $PSP | ? CanonicalName -eq "naa.60002ac0000000000000da5a00014e4a" | Set-ScsiLun -MultipathPolicy RoundRobin
$VMHost4 | Get-ScsiLun | ? MultipathPolicy -NotIn $PSP | ? CanonicalName -NotIn $ExcludeDevice | Set-ScsiLun -MultipathPolicy RoundRobin
$VMHost4 | Get-ScsiLun | ? MultipathPolicy -NotIn $PSP | ? CanonicalName -NotIn $ExcludeDevice | ft -AutoSize 
$VMHost4 | Get-ScsiLun | ? MultipathPolicy -NotIn $PSP | ft -AutoSize
$VMHost4 | Get-ScsiLun | ? MultipathPolicy -NotIn $PSP | Set-ScsiLun -MultipathPolicy RoundRobin
#ft -AutoSize

#Set-ScsiLun -MultipathPolicy RoundRobin

#naa.60002ac0000000000000da6300014e4a

#>