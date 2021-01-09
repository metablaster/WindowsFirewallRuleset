
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

<#
.SYNOPSIS
Unit test for Get-SDDL

.DESCRIPTION
Test correctness of Get-SDDL function

.PARAMETER Force
If specified, no prompt to run script is shown.

.EXAMPLE
PS> .\Get-SDDL.ps1

.INPUTS
None. You cannot pipe objects to Get-SDDL.ps1

.OUTPUTS
None. Get-SDDL.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\ContextSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

<#
.SYNOPSIS
Validate SDDL string

.DESCRIPTION
Check if SDDL string has valid syntax

.PARAMETER SDDL
Security Descriptor Definition Language string

.PARAMETER Force
If specified, no prompt to run script is shown.

.EXAMPLE
PS> Get-SDDL -Group @("Users", "Administrators") | Test-SDDL

.INPUTS
[string]

.OUTPUTS
[string]

.NOTES
TODO: This needs better place, and, more such validation functions are needed
#>
function Test-SDDL
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]] $SDDL
	)

	begin
	{
		$ACLObject = New-Object -TypeName System.Security.AccessControl.DirectorySecurity
	}
	process
	{
		foreach ($SddlString in $SDDL)
		{
			try
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Testing SDDL: $SddlString"

				# Set the security descriptor from the specified SDDL
				$ACLObject.SetSecurityDescriptorSddlForm($SddlString)
				Write-Output $SddlString
			}
			catch
			{
				Write-Error -Category InvalidArgument -TargetObject $SddlString -Message $_.Exception.Message -EV ErrorData
			}
		}
	}
}

Enter-Test

#
# Test groups
#

[string[]] $Groups = @("Users", "Administrators")

Start-Test "Get-SDDL -Group $Groups"
$Result = Get-SDDL -Group $Groups

Test-SDDL $Result
Test-Output $Result -Command Get-SDDL

Start-Test "Get-SDDL -Group $Groups -Merge"
Get-SDDL -Group $Groups -Merge | Test-SDDL

Start-Test "Get-SDDL -Group $Groups -CIM"
Get-SDDL -Group $Groups -CIM | Test-SDDL

Start-Test "Get-SDDL -Group $Groups -CIM -Merge"
Get-SDDL -Group $Groups -CIM -Merge | Test-SDDL

#
# Test users
#

[string[]] $Users = "Administrator", $TestAdmin, $TestUser

Start-Test "Get-SDDL -User $Users"
Get-SDDL -User $Users | Test-SDDL

Start-Test "Get-SDDL -User $Users -Merge"
Get-SDDL -User $Users -Merge | Test-SDDL

Start-Test "Get-SDDL -User $Users -CIM"
$Result = Get-SDDL -User $Users -CIM

Test-SDDL $Result
Test-Output $Result -Command Get-SDDL

Start-Test "Get-SDDL -User $Users -CIM -Merge"
$Result = Get-SDDL -User $Users -CIM -Merge
$Result | Test-SDDL

Test-Output $Result -Command Get-SDDL

#
# Test NT AUTHORITY
#

[string] $NTDomain = "NT AUTHORITY"
[string[]] $NTUsers = "SYSTEM", "LOCAL SERVICE"

Start-Test "Get-SDDL -Domain $NTDomain -User $NTUsers"
Get-SDDL -Domain $NTDomain -User $NTUsers | Test-SDDL

Start-Test "Get-SDDL -Domain $NTDomain -User $NTUsers -Merge"
Get-SDDL -Domain $NTDomain -User $NTUsers -Merge | Test-SDDL

#
# Test APPLICATION PACKAGE AUTHORITY
#

[string] $AppDomain = "APPLICATION PACKAGE AUTHORITY"
[string[]] $AppUser = "Your Internet connection", "Your pictures library"

Start-Test "Get-SDDL -Domain $AppDomain -User $AppUser"
Get-SDDL -Domain $AppDomain -User $AppUser | Test-SDDL

Start-Test "Get-SDDL -Domain $AppDomain -User $AppUser -Merge"
$Result = Get-SDDL -Domain $AppDomain -User $AppUser -Merge
$Result | Test-SDDL

Test-Output $Result -Command Get-SDDL

#
# Test paths
#

$FileSystem = "C:\Users\Public\Desktop\" # Inherited
$Registry1 = "HKCU:\" # Not Inherited
$Registry2 = "HKLM:\SOFTWARE\Microsoft\Clipboard"

Start-Test "Get-SDDL -Path FileSystem"
Get-SDDL -Path $FileSystem | Test-SDDL

Start-Test "Get-SDDL -Path Registry1"
Get-SDDL -Path $Registry1 | Test-SDDL

Start-Test "Get-SDDL -Path Registry2 -Merge"
$Result = Get-SDDL -Path $Registry2 -Merge
$Result | Test-SDDL

Test-Output $Result -Command Get-SDDL

Update-Log
Exit-Test
