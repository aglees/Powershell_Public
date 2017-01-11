$vCenterServer = "" # FQDN of vCenter Server

# version 1
Clear-Host

$ReportHeader = "VMHost service settings for [$(( Get-VIAccount | select -First 1 Server).Server)] on $(Get-Date -Format "dd MMMM yyyy")"
$underline = "=" * $ReportHeader.Length
Write-Host "$ReportHeader`n$underline`n" -ForegroundColor Green

Get-Cluster -server $vCenterServer | 
Get-VMHost  | 
select `
    @{Name="Cluster";Expression={(get-cluster -id $_.ParentId)}},
    Name, `
    @{Name="SSH Policy";Expression={ ($_ | Get-VMHostService | ? { $_.Label -match "SSH" } | select Policy ).Policy}}, `
    @{Name="SSH Running";Expression={ ($_ | Get-VMHostService | ? { $_.Label -match "SSH" } | select Running).Running}}, `
    @{Name="NTP Policy";Expression={ ($_ | Get-VMHostService | ? { $_.Label -match "NTP Daemon" } | select Policy ).Policy}}, `
    @{Name="NTP Running";Expression={ ($_ | Get-VMHostService | ? { $_.Label -match "NTP Daemon" } | select Running).Running}}, `
    @{Name="ESXi Shell Policy";Expression={ ($_ | Get-VMHostService | ? { $_.Label -match "ESXi Shell" } | select Policy ).Policy}}, `
    @{Name="ESXi Shell Running";Expression={ ($_ | Get-VMHostService | ? { $_.Label -match "ESXi Shell" } | select Running).Running}} | `
sort "Cluster", Name |
ft -AutoSize
