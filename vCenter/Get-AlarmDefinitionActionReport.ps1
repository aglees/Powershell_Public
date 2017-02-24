Function Underline([string]$String,[string]$Colour)
{
Write-Host "$String`n$("="*($String.Length))" -ForegroundColor $Colour
}

$Servers = ""#vCenter Server name here

Clear-Host

foreach($Server in $Servers){

    Write-Host "$Server`n$("="*($Server.Length))`n" -ForegroundColor Yellow

    $AlarmDefinitions = Get-AlarmDefinition -Server $Server | sort Name | ? {($_.Name -NotLike "Virtual SAN Health*")}

    foreach($AlarmDefinition in $AlarmDefinitions) {
        
        if(($AlarmDefinition | Get-AlarmAction))
        {

            Underline -String "$($AlarmDefinition.Name)" -Colour Yellow
            #Write-Host "$($AlarmDefinition.Name)`n$("="*($AlarmDefinition.Name).Length)" -ForegroundColor Yellow               
        
            Underline -String "Alarm Definition" -Colour Cyan
            $AlarmDefinition | ft -AutoSize
        
            # Gets all alarm actions
            try {
                $AlarmAction = Get-AlarmAction -Server $Server -AlarmDefinition $AlarmDefinition.Name -ErrorAction Stop
                Underline -String "Alarm Action" -Colour Cyan
                $AlarmAction | select * -ExcludeProperty Uid, Client, AlarmVersion | ft -AutoSize }
            catch { Write-Host "Not found.`n" -ForegroundColor Magenta }

            # this needs to get email specifics
            if(($AlarmDefinition | Get-AlarmAction -ActionType SendEmail))
            {
                try {
                    Underline -String "Alarm SMTP Action" -Colour Cyan
            
                    foreach($Action in ($AlarmDefinition | Get-AlarmAction -ActionType SendEmail)){
                        $Action | select * -ExcludeProperty Uid, Client, AlarmVersion | ft -AutoSize }
                }
                catch { Write-Host "Not found.`n" -ForegroundColor Magenta }
            }
        } #foreach alarmdefinition 
    }#end if                  
} #end foreach servers