Param(
    [parameter(Mandatory)][int]$Days
)

$OS = Get-wmiobject Win32_OperatingSystem
$Uptime = (Get-Date) - $OS.ConvertToDateTime($OS.LastBootUpTime)
$DaysUp = $Uptime.TotalDays
