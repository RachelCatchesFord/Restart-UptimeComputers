Param(
    [parameter(Mandatory)][int]$Days,
    [parameter(Mandatory)][int]$Hours
)

$OS = Get-wmiobject Win32_OperatingSystem
$Uptime = (Get-Date) - $OS.ConvertToDateTime($OS.LastBootUpTime)
[int]$DaysUp = $Uptime.TotalDays

if($DaysUp -ge $Days){
    $Tomorrow = (Get-Date).AddDays(1).Date.AddHours($Hours)
    msg.exe * "Your computer has been up for $($DaysUp) days. Scheduling a restart for $($Tomorrow)."
    shutdown -r -t ([decimal]::round($Tomorrow - (Get-Date).TotalSeconds))
}