
. "$PSScriptRoot\Functions.ps1"

$Platform = "10.0+" #Windows 10 and above
$PolicyStore = "localhost"
$OnError = "Stop"
$Debug = $false

# System users
$NT_AUTHORITY_SYSTEM = "D:(A;;CC;;;S-1-5-18)"
$NT_AUTHORITY_LOCAL_SERVICE = "D:(A;;CC;;;S-1-5-19)"

# Other users
$User = Get-UserSDDL User
$Admin = Get-UserSDDL Admin
