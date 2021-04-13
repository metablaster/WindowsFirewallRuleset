
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2016 Warren Frame

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
Takes a PSCredential object and validates it

.DESCRIPTION
Takes a PSCredential object and validates it against a domain or local machine

.PARAMETER Credential
A PSCredential object with the username/password which is to be tested.
Typically this is generated using the Get-Credential cmdlet.

.PARAMETER Context
Specifies the type of store to which the principal belongs:
Domain:
The domain store. This represents the AD DS store.
Machine:
The computer store. This represents the SAM store.
ApplicationDirectory:
The application directory store. This represents the AD LDS store.

.PARAMETER Domain
Target computer against which to test local credential object

.EXAMPLE
PS> $Cred = Get-Credential
PS> Test-Credential $Cred -Context Machine

.EXAMPLE
PS> $Cred = Get-Credential
PS> Test-Credential $Cred -Domain Server01 -Context Domain

.EXAMPLE
PS> @($Cred1, $Cred2, $Cred3) | Test-Credential -CN Server01 -Context Domain

.INPUTS
[PSCredential]

.OUTPUTS
[bool] true if the credentials are valid, otherwise false

.NOTES
Modifications by metablaster January 2021:
Function interface reworked by removing unnecesarry parameter and changin param block
Simplified logic to validate credential based on context type
Added links, inputs, outputs and notes to comment based help
TODO: Does not seem to work on LAN, try with Domain\User + pwd and:
https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-firewall/create-inbound-rules-to-support-rpc

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Test-Credential.md

.LINK
https://github.com/RamblingCookieMonster/PowerShell

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.directoryservices.accountmanagement.principalcontext
#>
function Test-Credential
{
	# NOTE: SuppressMessageAttribute not working for manual analyzer run, type disabled in PSScriptAnalyzerSettings
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
		"PSUseCompatibleTypes", "", Scope = "Function", Justification = "PS 5.1.17763 is out of date")]
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Test-Credential.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[PSCredential] $Credential,

		[Parameter(Mandatory = $true)]
		[ValidateSet("Domain", "Machine", "ApplicationDirectory")]
		[string] $Context,

		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		# Create principal context with appropriate context from param. If either comp or domain is null, thread's user's domain or local machine are used
		if ($Context -eq 'ApplicationDirectory' )
		{
			# Name=$null works for machine/domain, not applicationdirectory
			$DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext(
				[System.DirectoryServices.AccountManagement.ContextType]::$Context)
		}
		else
		{
			$DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext(
				[System.DirectoryServices.AccountManagement.ContextType]::$Context, $Domain)
		}
	}
	process
	{
		# Validate provided credential
		Write-Information -Tags $MyInvocation.InvocationName `
			-MessageData "INFO: Validating credential for user '$($Credential.UserName)'"
		$DS.ValidateCredentials($Credential.UserName, $Credential.GetNetworkCredential().password)
	}
	end
	{
		$DS.Dispose()
	}
}
