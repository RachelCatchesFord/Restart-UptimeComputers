Param(
    [Parameter(Mandatory = $true,Position = 0)][String]$Destination,
    [Parameter(Mandatory = $true,Position = 1)][String]$Domain
)

## Copy PSADT to local machine
Copy-Item -Path . -Destination $Destination -Force -Recurse




## Scheduled Task goes here