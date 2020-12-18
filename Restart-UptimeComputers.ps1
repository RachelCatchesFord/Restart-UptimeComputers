Param(
    [parameter(Mandatory)][int]$Days,
    [parameter(Mandatory)][int]$Hours
)

$OS = Get-wmiobject Win32_OperatingSystem
$Uptime = (Get-Date) - $OS.ConvertToDateTime($OS.LastBootUpTime)
[int]$DaysUp = $Uptime.TotalDays

if($DaysUp -ge $Days){
    $Tomorrow = [decimal]::round((Get-Date).AddDays(1).Date.AddHours($Hours))
    msg.exe * "Your computer has been up for $($DaysUp). Scheduling a restart for $($Tomorrow)."
    shutdown -r -t ($Tomorrow - (Get-Date).TotalSeconds)
}