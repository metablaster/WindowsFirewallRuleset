
. "$PSScriptRoot\Modules\Functions.ps1"

# Remove previous test
# Remove-NetFirewallRule -PolicyStore "localhost" -Group "Test" -Direction Inbound -ErrorAction SilentlyContinue
# Remove-NetFirewallRule -PolicyStore "localhost" -Group "Test" -Direction Outbound -ErrorAction SilentlyContinue

<# 
New-NetFirewallRule -ErrorAction Stop -PolicyStore "localhost" `
-DisplayName "Test Rule" -Service Any -Program Any `
-Enabled False -Action Allow -Group "Test" -Profile Domain -InterfaceType Any `
-Direction Inbound -Protocol UDP -LocalAddress Any -RemoteAddress PlayToDevice -LocalPort PlayToDiscovery -RemotePort Any `
-LocalUser Any -EdgeTraversalPolicy Block
 #>

<# New-NetFirewallRule -ErrorAction Stop -PolicyStore "localhost" `
-DisplayName "Test Rule" -Service Any -Program Any `
-Enabled False -Action Allow -Group "Test" -Profile Domain -InterfaceType Any `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress IntranetRemoteAccess -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)"
 #>
# ParseSDDL "D:(A;;CC;;;S-1-5-19)"

# Get-UserSDDL uSER

<# Write-Host "";
Write-Host "PSVersion: $($PSVersionTable.PSVersion)";
Write-Host "";
Write-Host "`$PSCommandPath:";
Write-Host " *   Direct: $PSCommandPath";
Write-Host " * Function: $(ScriptName)";
Write-Host "";
Write-Host "`$MyInvocation.ScriptName:";
Write-Host " *   Direct: $($MyInvocation.ScriptName)";
Write-Host " * Function: $(ScriptName)";
Write-Host "";
Write-Host "`$MyInvocation.MyCommand.Name:";
Write-Host " *   Direct: $($MyInvocation.MyCommand.Name)";
Write-Host " * Function: $(MyCommandName)";
Write-Host "";
Write-Host "`$MyInvocation.MyCommand.Definition:";
Write-Host " *   Direct: $($MyInvocation.MyCommand.Definition)";
Write-Host " * Function: $(MyCommandDefinition)";
Write-Host "";
Write-Host "`$MyInvocation.PSCommandPath:";
Write-Host " *   Direct: $($MyInvocation.PSCommandPath)";
Write-Host " * Function: $(PSCommandPath)";
Write-Host "";
 #>
$ScriptPath = Split-Path $MyInvocation.InvocationName

& "$ScriptPath\IPv4\Outbound\WirelessDisplay.ps1"
