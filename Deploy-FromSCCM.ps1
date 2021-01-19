Param(
    [Parameter(Mandatory = $true,Position = 0)][String]$Destination
)

## Copy PSADT to local machine
if(Test-Path -Path $Destination){
    Remove-Item -Path $Destination -Recurse -Force 
}

Copy-Item -Path . -Destination $Destination -Force -Recurse
