
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021 metablaster zebal@protonmail.ch

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
Disconnect remote computer

.DESCRIPTION
Disconnect remote computer previously connected with Connect-Computer.
This procedure releases any sessions established with remote host and
removes resources created during a session.

.PARAMETER Domain
Computer name which to disconnect

.EXAMPLE
PS> Disconnect-Computer

.INPUTS
None. You cannot pipe objects to Disconnect-Computer

.OUTPUTS
None. Disconnect-Computer does not generate any output

.NOTES
TODO: If there are multiple connections, remove only specific ones
#>
function Disconnect-Computer
{
	[CmdletBinding()]
	[OutputType([void])]
	param (
		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if (Get-Variable -Name RemoteCredential -Scope Global -EA Ignore)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Removing variable 'RemoteCredential'"
		Remove-Variable -Name RemoteCredential -Scope Global -Force
	}

	if (Get-CimSession -Name RemoteCim -EA Ignore)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Removing CIM session 'RemoteCim'"
		Remove-CimSession -Name RemoteCim
	}

	if (Get-Variable -Name CimServer -Scope Global -EA Ignore)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Removing variable 'CimServer'"
		Remove-Variable -Name CimServer -Scope Global -Force
	}

	if (Get-PSDrive -Name RemoteRegistry -Scope Global -EA Ignore)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Removing PSDrive 'RemoteRegistry'"
		Remove-PSDrive -Name RemoteRegistry -Scope Global
	}

	Exit-PSSession
}
