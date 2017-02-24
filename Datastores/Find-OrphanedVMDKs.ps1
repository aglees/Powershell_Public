# FIND ORPHANED VMDKS
$vCenterServer = "" # FQDN vCenter Server

# get all VMs
$VMs = Get-VM -Server $vCenterServer | sort Name

# get all VMDKs for all VMs
$All_VMDKs = @()
$i = 0

foreach($VM in $VMs) {
    
    $progParam=@{
        Activity = "Get list of VMDKs for each virtual machine"
        CurrentOperation=$VM.Name
        Status="Querying VM hard disks"
        PercentComplete=($i/($VMs.Length))*100
        }
    
    Write-Progress @progParam

    $Devices = $VM.ExtensionData.Config.Hardware.Device
    $VMDKs = $Devices.Backing.FileName | sort   
    $All_VMDKs += $VMDKs

    $i++

}

# generate base search path, and get list of datastores
$BasePath = "vmstores:\$vCenterServer@443\$((Get-Datacenter -Server $vCenterServer).Name)\"
$Datastores = dir -Path $BasePath

# setup files to exclude
# excluding snapshot files could be mistake if VM is running off snapshots
$exclusion = ('*-ctk.vmdk', '*-delta.vmdk', '*-rdmp.vmdk','*-000001.vmdk')

# create array to hold data
$Array = @()
$i = 0

# loop through each datastore
foreach($Datastore in $Datastores) {
    
    $progParam=@{
        Activity = "Get list of VMDKs on each datastore"
        CurrentOperation=$Datastore.Name
        Status="Querying VMDK on datastore"
        PercentComplete=($i/($Datastores.Length))*100
        }
    
    Write-Progress @progParam

    #Write-Host "`n$($Datastore.Name)`n$("="*(($Datastore.Name).length))" -ForegroundColor Yellow

    # get VMDK files 
    $files = $Datastore | dir -Recurse -Include '*.vmdk' -exclude $exclusion 

    # check if file is not -flat and then process
    foreach($file in ($files | ? DatastoreFullPath -NotLike "*-flat.vmdk")) { 
        
        # check if file is not part of virtual machine
        if($All_VMDKs -notcontains $file.DatastoreFullPath) {
            
            # get flat file from existing file path
            # this is a guess at that path - could do better       
            $FlatFilePath = $file.FullName.Replace(".vmdk","-flat.vmdk")
            $FlatFile = $files | ? FullName -EQ $FlatFilePath
            $Size = [math]::Round($FlatFile.length/1GB, 1)
            
            # add data to hash table
            $Hash = [ordered]@{}
            $Hash.Datastore = $file.Datastore
            $Hash.DatastoreFullPath = $file.DatastoreFullPath
            $Hash.FullName = $file.FullName
            $Hash.LastWriteTime = $file.LastWriteTime
            $Hash.FlatFileFullName = $FlatFile.FullName
            $Hash.FlatFileDatastoreFullPath = $FlatFile.DatastoreFullPath
            $Hash.FlatFileLastWriteTime = $FlatFile.LastWriteTime
            $Hash.Size = $Size
            
            # create object from hash, and add to array
            $Object = New-Object -TypeName PSObject -Property $Hash
            $Array += $Object

            Write-Host "$($file.DatastoreFullPath):`t$($Size.ToString()+" GB")"
        }
    }

    $i++

}

#$Array | ft -AutoSize

$reportDatastores = $Array | select -Unique Datastore

foreach($reportDatastore in $reportDatastores.Datastore) {

    Write-Host "`n$reportDatastore`n$("="*($reportDatastore.Name).length)" -ForegroundColor Yellow
    $Array | ? { <#($_.LastWriteTime -LT '01/01/2017') -and #> ($_.Datastore -eq $reportDatastore) } | sort LastWriteTime -Descending |  ft -AutoSize DatastoreFullPath, LastWriteTime, Size

}

<#
$Array | Get-Member
$Array | ? LastWriteTime -LT '01/01/2017' | sort Datastore, LastWriteTime -Descending |  ft -AutoSize DatastoreFullPath, LastWriteTime, Size
$Array | ? LastWriteTime -LT '01/01/2017' | measure size -Sum
#>
