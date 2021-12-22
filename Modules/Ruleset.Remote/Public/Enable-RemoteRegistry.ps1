
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
Enable remote registry

.DESCRIPTION
Starts the RemoteRegistry service and adds required firewall rules
which enables remote users to modify registry settings on this computer.

.EXAMPLE
PS> Enable-RemoteRegistry

.INPUTS
None. You cannot pipe objects to Enable-RemoteRegistry

.OUTPUTS
None. Enable-RemoteRegistry does not generate any output

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Enable-RemoteRegistry.md
#>
function Enable-RemoteRegistry
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Enable-RemoteRegistry.md")]
	[OutputType([void])]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Checking remote registry requirements"

	# Determine whether GPO firewall is active
	$GpoStore = $null -ne (Get-NetFirewallProfile -Profile Private -PolicyStore ([System.Environment]::MachineName) |
		Where-Object { $_.Enabled -eq $true })

	if ($GpoStore)
	{
		$Store = [System.Environment]::MachineName
	}
	else
	{
		$Store = "PersistentStore"
	}


	$AllRuleGroups = @(
		# File and Printer Sharing
		"@FirewallAPI.dll,-28502"

		# Network Discovery
		"@FirewallAPI.dll,-32752"
	)

	if ($PSCmdlet.ShouldProcess("Windows firewall, persistent store", "Add and enable firewall rules to allow remote registry"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Adding and enabling firewall rules to allow remote registry"

		# TODO: Only private profile should be affected on workstation machines
		foreach ($RuleGroup in $AllRuleGroups)
		{
			Remove-NetFirewallRule -Group $RuleGroup -PolicyStore $Store -Direction Inbound -EA Ignore
			Remove-NetFirewallRule -Group $RuleGroup -PolicyStore $Store -Direction Outbound -EA Ignore

			Copy-NetFirewallRule -PolicyStore SystemDefaults -Group $RuleGroup -Direction Inbound -NewPolicyStore $Store
			Copy-NetFirewallRule -PolicyStore SystemDefaults -Group $RuleGroup -Direction Outbound -NewPolicyStore $Store

			Get-NetFirewallRule -Group $RuleGroup -PolicyStore $Store -Direction Inbound | Enable-NetFirewallRule
			Get-NetFirewallRule -Group $RuleGroup -PolicyStore $Store -Direction Outbound | Enable-NetFirewallRule
		}
	}

	if ($PSCmdlet.ShouldProcess("Windows services", "Enable and start remote registry service"))
	{
		$RegService = Get-Service -Name RemoteRegistry

		if ($RegService.StartType -ne [ServiceStartMode]::Automatic)
		{
			if ($PSCmdlet.ShouldProcess($RegService.DisplayName, "Set service to automatic startup"))
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting $($RegService.DisplayName) service to automatic startup"
				Set-Service -InputObject $RegService -StartupType Automatic
			}
		}

		if ($RegService.Status -ne [ServiceControllerStatus]::Running)
		{
			if ($PSCmdlet.ShouldProcess($RegService.DisplayName, "Start service"))
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Starting $($RegService.DisplayName) service"
				$RegService.Start()
				$RegService.WaitForStatus([ServiceControllerStatus]::Running, $ServiceTimeout)
			}
		}
	}
}
