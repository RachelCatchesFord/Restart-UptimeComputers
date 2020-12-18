Param(
    [parameter(Mandatory)][int]$Days,
    [parameter(Mandatory)][int]$Hours
)

$OS = Get-wmiobject Win32_OperatingSystem
$Uptime = (Get-Date) - $OS.ConvertToDateTime($OS.LastBootUpTime)
[int]$DaysUp = $Uptime.TotalDays

if($DaysUp -ge $Days){
    shutdown -r -t ([decimal]::round(((Get-Date).AddDays(1).Date.AddHours($Hours) - (Get-Date)).TotalSeconds))
}