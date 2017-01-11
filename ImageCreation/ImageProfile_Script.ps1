<#
.SYNOPSIS
  Generate ESXi Image Profile from an offline bundle, whilst replace drivers from a given offline driver bundle. 
.DESCRIPTION
  This script can be useful for generating custome ESXi images for older HPE servers, where there are known issues with Emulex driver compatibility. 
.INPUTS
  None. All inputs are Variables at the top of the script. Set appropriately before running
.OUTPUTS
  A custom ESXi ISO file at the location specified.
.NOTES
  Version:        0.2
  Author:         Andrew Gleeson @aglees
  Creation Date:  9 November 2016
  Purpose/Change: Initial script development
  
.EXAMPLE
  See variables in script.
#>


$ErrorActionPreference = "Stop"

#Base Variables
# review these and set as appropriate before running
$Path_Original_ESXi_OfflineBundle = "C:\~~~\VMware-ESXi-5.5.0-Update3-3116895-HP-550.9.4.26-Nov2015-depot.zip"
$Path_VIB_to_Add = "C:\~~~~\VMW-ESX-5.5.0-elxnet-10.7.110.44-4014197\VMW-ESX-5.5.0-elxnet-10.7.110.44-offline_bundle-4014197.zip" # script can only handle one vib, and one vendor
$Path_Modified_ESXiImage = "C:\~~~~\ESXi\" # output path for iso
$AcceptanceLevel = "PartnerSupported" # select from [CommunitySupported, PartnerSupported, VMwareAccepted, VMwareCertified]
$ESXProfileVendor = "Hewlett Packard Enterprise" # add your Profile Vendor 

#Image profile suffix
# sets the image profile suffix depending on the acceptance level
# if not set the default -MOD is used
$ImageProfileSuffix = ""
switch ($AcceptanceLevel)
{
    'CommunitySupported' { $ImageProfileSuffix = "-MOD-CommSup" }
    'PartnerSupported' { $ImageProfileSuffix = "-MOD-PartSup" }
    'VMwareAccepted' { $ImageProfileSuffix = "-MOD-VMwaAcc" }
    'VMwareCertified' { $ImageProfileSuffix = "-MOD-VMwaCer" }
    Default { $ImageProfileSuffix = "MOD" }
}

#Remove currently loaded software depots
try { Get-EsxSoftwareDepot|  Remove-EsxSoftwareDepot }
catch {}

#Add Software Depot
try { Add-EsxSoftwareDepot -DepotUrl $Path_Original_ESXi_OfflineBundle }
catch { Write-Host "Error adding image of ESXi Offline Bundle" -ForegroundColor Red; break; }

try { Add-EsxSoftwareDepot -DepotUrl $Path_VIB_to_Add }
catch { Write-Host "Error adding image of VIB Offline Bundle" -ForegroundColor Red; break; }

#Display mounted Software Depots
Get-EsxSoftwareDepot

#Check software packages in ESXi Image
Get-EsxSoftwareDepot | ? DepotUrl -like "*$Path_Original_ESXi_OfflineBundle*" | Get-EsxSoftwarePackage

#Setup VIB Software Packages variable
$VIB_SoftwarePackages = Get-EsxSoftwareDepot | ? DepotUrl -like "*$Path_VIB_to_Add*" | Get-EsxSoftwarePackage

#Setup modified image profile name
$Original_ESXProfile_Name = (Get-EsxImageProfile)[0].Name
$Modified_ESXProfile_Name = $Original_ESXProfile_Name + $ImageProfileSuffix

#Clone original image profile
New-EsxImageProfile -CloneProfile $Original_ESXProfile_Name -Name $Modified_ESXProfile_Name -Vendor $ESXProfileVendor  -AcceptanceLevel $AcceptanceLevel

#Display list of image profiles
Get-EsxImageProfile | ft -AutoSize

#Display list of software packags in image that match those in the VIB
$NewImage = Get-EsxImageProfile -Name $Modified_ESXProfile_Name
$NewImage.VibList | ? Vendor -eq ($VIB_SoftwarePackages[0].Vendor) | sort Name | ft -AutoSize

#Remove software packages from image that match those in VIB
Remove-EsxSoftwarePackage -ImageProfile $Modified_ESXProfile_Name -SoftwarePackage ($VIB_SoftwarePackages[0].Name)

#Display list of software depots and software packages matching VIB vendor
Get-EsxSoftwareDepot
Get-EsxSoftwarePackage | ? Vendor -eq ($VIB_SoftwarePackages[0].Vendor) | sort Name | ft -AutoSize

#Setup variable for software package to add to image
$SoftwarePackage = ($VIB_SoftwarePackages[0].Name) + " " + ($VIB_SoftwarePackages[0].Version)

#Add VIB software package to image
Add-EsxSoftwarePackage -ImageProfile $Modified_ESXProfile_Name -SoftwarePackage $SoftwarePackage

#Compare original and modified images
$CompareObj = Compare-EsxImageProfile -ReferenceProfile $Original_ESXProfile_Name -ComparisonProfile $Modified_ESXProfile_Name
$CompareObj

#Setup path to exported iso
$Path_Modified_ESXiImage = $Path_Modified_ESXiImage + $Modified_ESXProfile_Name + ".iso"

#Export image to ISO
Export-EsxImageProfile -ImageProfile $Modified_ESXProfile_Name -FilePath $Path_Modified_ESXiImage -ExportToIso