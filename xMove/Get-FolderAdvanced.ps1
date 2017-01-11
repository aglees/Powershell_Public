<#
.Synopsis
   Returns a VMware PowerCli virtual machine folder given a "parent\folder" input string.
.NOTES
   File Name  : Get-FolderAdvanced.ps1
   Author     : Andrew Gleeson - @aglees
   Version    : 1.0
.DESCRIPTION
   Uses the PowerCli Get-Folder cmdlet to return a specific folder based on your input string. 
   The input string can comprise the parent and desired folder name. 
   If no parent is provided the root VM folder of the datacenter will be used as parent.
   If no folder is provided, the root VM folder of the datacenter will be used as the folder.
.EXAMPLE
   $Datacenter = ""
   $Target = "Working_Links_038952\Infrastructure"
   Get-Folder-Advanced -MyFolder $Target -Datacenter $Datacenter -Conn $conn
.EXAMPLE
   $Target = "Easynet Mgmt"
   Get-Folder-Advanced -MyFolder $Target -Datacenter $Datacenter -Conn $conn
#>
function Get-Folder-Advanced
{
    [OutputType([VMware.VimAutomation.ViCore.Impl.V1.Inventory.FolderImpl])]
    Param
    (
        # Param1 MyFolder << the folder to search for >>
        [Parameter(Mandatory=$false, 
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$MyFolder="",

        # Param2 Datacenter << the datacenter to search >>
        [string]$Datacenter="",
        
        # Param 3 Conn << vCenter connection >>
        [VMware.VimAutomation.ViCore.Impl.V1.VIServerImpl]$Conn
    )

    Begin
    {
        # pad $Folder if missing '\'
        if($MyFolder -notmatch "\\") { $MyFolder = "\"+$MyFolder }

        #split Folder in Parent and Folder 
        $Folder = $MyFolder -split '\\'
        $Parent = $Folder[0]
        $Folder = $Folder[1]
    }
    Process
    {

        # get Parent PowerCli object
        if(!$Parent) { # if there is no defined Parent folder
            if($Folder) { # if there is a defined Folder folder, get the child folder of the datacenter and use that as Parent
                $Parent = Get-Folder -Type VM -Server $conn | ? Parent -eq (Get-Datacenter -Name $Datacenter -Server $conn) 
            }
            else { # if there is no defined Folder folder, use defined datacenter as Parent
                $Parent = Get-Datacenter -Name $Datacenter
            }
        }
        else { # use the defined Parent folder
            $Parent = Get-Folder -Type VM -Name $Parent -Server $conn
        } 

        # get Folder PowerCli object
        $FolderFound = $false # set found boolean to false
        foreach ($uniqueParent in $Parent) { # iterate through all returned Parent folders
            if(!$FolderFound) { # check the found boolean
                if($Folder) { # if a defined folder is present, get Folder using Folder and defined parent
                    $Folder = get-folder -Name $Folder -Type VM -Server $conn | ? Parent -eq $uniqueParent
                }
                else { # if there is no defined folder, get the folder using only defined parent
                    $Folder = Get-Folder -Type VM -Server $conn | ? Parent -eq $uniqueParent
                }
            }
            if($Folder) { $FolderFound = $true} # set found boolean once a folder has been found
        }
 
    } #end Process
    End
    {
        return $Folder
    } #end End
} # end Function

