
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2024 metablaster zebal@protonmail.ch

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
Unit test for Get-PathSDDL

.DESCRIPTION
Test correctness of Get-PathSDDL function

.PARAMETER Domain
If specified, only remoting tests against specified computer name are performed

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Get-PathSDDL.ps1

.INPUTS
None. You cannot pipe objects to Get-PathSDDL.ps1

.OUTPUTS
None. Get-PathSDDL.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project
Import-Module -Name Ruleset.UserInfo
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
If specified, no prompt to run script is shown

.EXAMPLE
PS> Get-PathSDDL -Group @("Users", "Administrators") | Test-SDDL

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
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Testing SDDL '$SddlString'"

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

Enter-Test "Get-PathSDDL"

if ($Domain -ne [System.Environment]::MachineName)
{
	$RemotePath = "C:\Users\Public\Desktop\" # Inherited
	$RemoteUNCPath = "\\$Domain\C$\Windows"

	# NOTE: This will fail on HTTPS enabled remote because it will use HTTP
	Start-Test "-Path remote FileSystem -Domain"
	Get-PathSDDL -Path $RemotePath -Domain $Domain -Credential $RemotingCredential | Test-SDDL

	Start-Test "-Path remote FileSystem Session -Merge"
	Get-PathSDDL -Path $RemotePath -Session $SessionInstance -Merge | Test-SDDL

	Start-Test "-Path remote UNC path Session"
	Get-PathSDDL -Path $RemoteUNCPath -Session $SessionInstance | Test-SDDL
}
else
{
	$FileSystem = "C:\Users\Public\Desktop\" # Inherited
	$Registry1 = "HKCU:\" # Not Inherited
	$Registry2 = "HKLM:\SOFTWARE\Microsoft\Clipboard"

	Start-Test "-Path FileSystem"
	Get-PathSDDL -Path $FileSystem | Test-SDDL

	Start-Test "-Path Registry1"
	Get-PathSDDL -Path $Registry1 | Test-SDDL

	Start-Test "-Path Registry2 -Merge"
	$Result = Get-PathSDDL -Path $Registry2 -Merge
	$Result | Test-SDDL

	Test-Output $Result -Command Get-PathSDDL
}

Update-Log
Exit-Test
