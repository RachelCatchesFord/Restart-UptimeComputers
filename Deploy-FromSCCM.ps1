Param(
    [Parameter(Mandatory = $true,Position = 0)][String]$Destination,
    [Parameter(Mandatory = $true,Position = 1)][String]$Domain
)

$TaskName = 'MandatoryReboot'

## Copy PSADT to local machine
if(Test-Path -Path $Destination){
    Remove-Item -Path $Destination -Recurse -Force 
}

Copy-Item -Path . -Destination $Destination -Force -Recurse

## Scheduled Task goes here
if(Get-ScheduledTask -TaskName $TaskName){
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

#New scheduled task to trigger at logon or unlock
$stateChangeTrigger = Get-CimClass `
    -Namespace ROOT\Microsoft\Windows\TaskScheduler `
    -ClassName MSFT_TaskSessionStateChangeTrigger

$onUnlockTrigger = New-CimInstance `
    -CimClass $stateChangeTrigger `
    -Property @{
        StateChange = 8  # TASK_SESSION_STATE_CHANGE_TYPE.TASK_SESSION_UNLOCK (taskschd.h)
    } `
    -ClientOnly


$ActionPath = "$Destination"
$action = New-ScheduledTaskAction -WorkingDirectory $ActionPath -Execute "Deploy-Application.exe"
$trigger = @(
$(New-ScheduledTaskTrigger -AtLogOn), 
$($onUnlockTrigger)
)

Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $TaskName -Description 'Automagically reboots the machine if Uptime is 7+ days.' -User $env:USERNAME -RunLevel Highest
Start-ScheduledTask -TaskName $TaskName