. 'C:\Users\admin_AGleeson\Documents\WindowsPowerShell\Functions\xMove-VM.ps1'
. 'C:\Users\admin_AGleeson\Documents\WindowsPowerShell\Functions\Test-xMove-VMInfo.ps1'
. 'C:\Users\admin_AGleeson\Documents\WindowsPowerShell\Functions\Get-xMove-VMInfo.ps1'
. 'C:\Users\admin_AGleeson\Documents\WindowsPowerShell\Functions\Get-FolderAdvanced.ps1'

<#
.Synopsis
   Complete script for moving VMs between virtual centers, based on a given VM folder.
.NOTES
   File Name  : xMove-VM-v5.ps1
   Author     : Andrew Gleeson - @aglees
   Version    : 1.5
.DESCRIPTION
   Complete script for moving VMs between virtual centers, based on a given VM folder.
   Utilizes a number of scripts for getting & checking information, and [William Lam - @lamw]'s 
   script for xMove'ing VMs between vCenters.
.EXAMPLE
   Edit the variables set out below, and test run the script. 
   When those tests pass, and you're happy remove the fail safe elements and try again.
#>

# clear screen
Clear-Host

## Variables that must be defined ##
# Source vCenter variables
$sourceVC = "" # vCenter Server FQDN
$sourceVCUsername = "" # Administrative vCenter SSO account inc @yourdomain.tld
$sourceVCPassword = "" # Password
# Destination vCenter variables
$destVC = "" # vCenter Server FQDN
$destVCUsername = "" # Administrative vCenter SSO account inc @yourdomain.tld
$destVCpassword = "" # Password
# Source VM selection variables
$sourceDatacenter = "" # VMware Datacenter name
$sourceFolder = "" # VMware base source folder
$souceGetSubFolderVMs = $false # is this used anywhere?
# Destination variables
$destDatacenter = "" # VMware Datacenter name
$destClusterName = "" # VMware Cluster Name
$destVmHostName = "" # VMware Target ESXi Host FQDN
$destSwitchName = "" # VMware Target switch name 
$SwitchType = "vds" # vds or vss
# port and folder mappings from source to destination
$portMap = "C:\~~~\PortGroupMappings.txt" # Path to port group mappings
$folderMap = "C:\~~~~\FolderMappings.txt" # Path to folder mappings
## End Variables that must be defined ##

# Connect to Source/Destination vCenter Server
$sourceVCConn = Connect-VIServer -Server $sourceVC -user $sourceVCUsername -password $sourceVCPassword
$destVCConn = Connect-VIServer -Server $destVC -user $destVCUsername -password $destVCpassword

# Get xMove information
$xMoveInfo = Get-xMove-VMInfo -FolderTarget $sourceFolder `
                -PortGroupMappingPath $portMap `
                -FolderMappingPath $folderMap `
                -Datacenter $sourceDatacenter `
                -Recursive:$souceGetSubFolderVMs `
                -Conn $sourceVCConn

# Test xMove information versus destination VM host
$boolean_TestxMoveInfo = Test-xMove-VMInfo -xMoveVmInfo $xMoveInfo `
                            -DestVmHostName $destVmHostName `
                            -DestSwitchName $destSwitchName `
                            -DestDatacenter $destDatacenter `
                            -DestVcConn $destVCConn
                            
Write-Host "`nTestxMoveInfo " -NoNewline
if(!$boolean_TestxMoveInfo) { # xMove information test failed
    Write-Host "[FAILED]" -ForegroundColor Red
    break;
}
else { # xMove information test passed
    Write-Host "[PASSED]" -ForegroundColor Green
}

# fail-safe break. Remove to arm script.
Write-Host "`n`nxMove about to start"
break;

# xMove-VM to destination, and Move-VM to destination folder 
foreach($Info in $xMoveInfo) {

    $vmname = $Info.VM
    $datastorename = $Info.Datastores
    $vmnetworkname = $Info.Networks
    $folder = Get-Folder-Advanced -MyFolder $info.Folder -Datacenter $destDatacenter -Conn $destVCConn
        
    Write-Host "`n$($Info.VM)`n$("="*($Info.VM).Length)" -ForegroundColor Yellow
    Write-Host "Datastores:`t$datastorename"
    Write-Host "Networks:`t$vmnetworkname"
    Write-Host "Folder:`t$($folder.Name)"

    
    xMove-VM -sourcevc $sourceVCConn `
        -destvc $destVCConn `
        -VM $vmname `
        -switchtype $switchtype `
        -switch $destSwitchName `
        -cluster $destClusterName `
        -vmhost $destVmHostName `
        -datastore $datastorename `
        -vmnetwork  $vmnetworkname

    Move-VM -VM $vmname `
        -Destination $folder `
        -Server $destVCConn
    #>
}

# zero arrayInfo variable to prevent accidents
$xMoveInfo = @()

# Disconnect from Source/Destination VC
Disconnect-VIServer -Server $sourceVCConn -Confirm:$false
Disconnect-VIServer -Server $destVCConn -Confirm:$false