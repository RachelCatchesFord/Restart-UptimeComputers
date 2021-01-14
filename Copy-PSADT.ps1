Param(
    [Parameter(Mandatory = $true,Position = 0)][String]$Destination
)


Copy-Item -Path . -Destination $Destination -Force -Recurse