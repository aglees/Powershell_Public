$vCenterServer = "" # FQDN vCenter Server
$SearchString = ""

Connect-VIServer -Server $vCenterServer

$VMs = Get-Cluster | ? Name -Match "$SearchString*" | Get-VM | sort Name

foreach ($VM in $VMs) {

    Write-Host "$($VM.Name) : " -ForegroundColor Yellow -NoNewline 
    Write-Host "$(Get-Datastore -Id $VM.DatastoreIdList) : " -ForegroundColor Green -NoNewline
    $VM | Get-NetworkAdapter | foreach { Write-Host "$($_.NetworkName)  " -NoNewline }
    Write-Host
}
