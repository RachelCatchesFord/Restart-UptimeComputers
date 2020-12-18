Param(
    [parameter(Mandatory)][int]$Days,
    [parameter(Mandatory)][int]$Time
)

$OS = Get-wmiobject Win32_OperatingSystem
$Uptime = (Get-Date) - $OS.ConvertToDateTime($OS.LastBootUpTime)
[int]$DaysUp = $Uptime.TotalDays

if($DaysUp -ge $Days){
    $Tomorrow = (Get-Date).AddDays(1).Date.AddHours($Time)
    msg.exe * "***OIT DESKSIDE SUPPORT*** Your computer has been up for $($DaysUp) Days. Scheduling a restart for $($Tomorrow)."
    shutdown -r -t ([decimal]::round(($Tomorrow - (Get-Date)).TotalSeconds))
}