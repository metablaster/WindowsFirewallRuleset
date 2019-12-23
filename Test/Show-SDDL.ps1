
#
# Unit test for Parse-SDDL
#

Import-Module -Name $PSScriptRoot\..\FirewallModule

# Experiment with different path values to see what the ACL objects do
$path = "C:\users\User\" #Not inherited
# $path = "C:\users\username\desktop\" #Inherited
# $path = "HKCU:\" #Not Inherited
# $path = "HKCU:\Software" #Inherited
# $path = "HKLM:\" #Not Inherited

Write-Host ""
Write-Host "Path:"
Write-Host "************************"
$Path

Write-Host ""
Write-Host "ACL.AccessToString:"
Write-Host "************************"

$ACL = Get-ACL $path
$ACL.AccessToString

Write-Host ""
Write-Host "Access entry details:"
Write-Host "************************"

$ACL.Access | Format-list *

Write-Host ""
Write-Host "SDDL:"
Write-Host "************************"

$ACL.SDDL

# Call with named parameter binding 
# $ACL | Show-SDDL

# Or call with parameter string
Show-SDDL $ACL.SDDL

Write-Host ""
