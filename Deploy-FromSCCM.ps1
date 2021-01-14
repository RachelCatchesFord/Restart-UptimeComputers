Param(
    [Parameter(Mandatory = $true,Position = 0)][String]$Destination,
    [Parameter(Mandatory = $true,Position = 1)][String]$Domain
)

## Copy PSADT to local machine
Copy-Item -Path . -Destination $Destination -Force -Recurse


## Detect Logged on Users
$LoggedOnUsers = Get-Process -IncludeUserName | Select-Object UserName,SessionId | Where-Object {($_.UserName -ne $null) -and ($_.UserName -like "$Domain*")} | Sort-Object SessionId -Unique

if($LoggedOnUsers){
    Return $true
}

## Scheduled Task goes here