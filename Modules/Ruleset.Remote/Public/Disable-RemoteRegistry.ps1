
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
Disable remote registry

.DESCRIPTION
Disable-RemoteRegistry stops the RemoteRegistry service but does not remove firewall rules
previously configured by Enable-RemoteRegistry function

.EXAMPLE
PS> Disable-RemoteRegistry

.INPUTS
None. You cannot pipe objects to Disable-RemoteRegistry

.OUTPUTS
None. Disable-RemoteRegistry does not generate any output

.NOTES
TODO: Does not revert firewall rules because previous status is unknown

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Disable-RemoteRegistry.md
#>
function Disable-RemoteRegistry
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Disable-RemoteRegistry.md")]
	[OutputType([void])]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Disabling remote registry"

	if ($PSCmdlet.ShouldProcess("Windows services", "Disable and stop remote registry service"))
	{
		$RegService = Get-Service -Name RemoteRegistry

		if ($RegService.Status -ne [ServiceControllerStatus]::Stopped)
		{
			if ($PSCmdlet.ShouldProcess($RegService.DisplayName, "Stop service"))
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Stopping $($RegService.DisplayName) service"
				$RegService.Stop()
				$RegService.WaitForStatus([ServiceControllerStatus]::Stopped, $ServiceTimeout)
			}
		}

		if ($RegService.StartType -ne [ServiceStartMode]::Disabled)
		{
			if ($PSCmdlet.ShouldProcess($RegService.DisplayName, "Set service to disabled"))
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting $($RegService.DisplayName) service to disabled"
				Set-Service -InputObject $RegService -StartupType Disabled
			}
		}
	}
}
