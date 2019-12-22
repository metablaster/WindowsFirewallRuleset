
#
# Unit test for Parse-SDDL
#

. "$PSScriptRoot\..\Modules\Functions.ps1"

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
# $ACL | ParseSDDL

# Or call with parameter string
Parse-SDDL $ACL.SDDL

Write-Host ""
