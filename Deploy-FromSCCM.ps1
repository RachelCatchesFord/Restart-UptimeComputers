Param(
    [Parameter(Mandatory = $true,Position = 0)][String]$Destination,
    [Parameter(Mandatory = $true,Position = 1)][String]$Domain
)

## Copy PSADT to local machine
Copy-Item -Path . -Destination $Destination -Force -Recurse




## Scheduled Task goes here

if(Get-ScheduledTask -TaskName 'MandatoryReboot'){
    Unregister-ScheduledTask -TaskName 'MandatoryReboot'
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

$ActionPath = "C:\Program Files\OIT\Restart-UptimeComputersPSADT"
$action = New-ScheduledTaskAction -WorkingDirectory $ActionPath -Execute "Deploy-Application.exe"
$trigger = @(
$(New-ScheduledTaskTrigger -AtLogOn), 
$($onUnlockTrigger)
)

Register-ScheduledTask -Action $action -Trigger $trigger -TaskName 'MandatoryReboot' -Description 'Automagically reboots the machine if Uptime is 7+ days.' -User 'System'
Start-ScheduledTask -TaskName 'MandatoryReboot'