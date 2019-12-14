
# Find current script path
$ScriptPath = Split-Path $MyInvocation.InvocationName

# PSScriptRoot is automatic variable introduced in Powershell 3
if(!$PSScriptRoot)
{
    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

#
# Execute IPv4 rules
#

# Load Inbound rules
& "$ScriptPath\IPv4\Inbound\ICMP.ps1"
& "$ScriptPath\IPv4\Inbound\BasicNetworking.ps1"

# Load Outbound rules
& "$ScriptPath\IPv4\Outbound\BasicNetworking.ps1"
& "$ScriptPath\IPv4\Outbound\ICMP.ps1"
& "$ScriptPath\IPv4\Outbound\MicrosoftOffice.ps1"
& "$ScriptPath\IPv4\Outbound\MicrosoftSoftware.ps1"
& "$ScriptPath\IPv4\Outbound\VisualStudio.ps1"
& "$ScriptPath\IPv4\Outbound\WindowsServices.ps1"
& "$ScriptPath\IPv4\Outbound\WindowsSystem.ps1"
