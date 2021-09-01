
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
Initialize WinRM service

.DESCRIPTION
Starts the WinRM service, Windows Remote Management (WS-Management) and set it to
automatic startup.
Adds required firewall rules to be able to configure service options.

.EXAMPLE
PS> Initialize-WinRM

.INPUTS
None. You cannot pipe objects to Initialize-WinRM

.OUTPUTS
None. Initialize-WinRM does not generate any output

.NOTES
None.
#>
function Initialize-WinRM
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
	[OutputType([void])]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Checking WS-Management (WinRM) requirements"

	# NOTE: "Windows Remote Management" predefined rules (including compatibility rules) if not
	# present may cause issues adjusting some of the WinRM options
	if (!(Get-NetFirewallRule -Group $WinRMRules -PolicyStore PersistentStore -EA Ignore))
	{
		if ($PSCmdlet.ShouldProcess("Windows firewall, persistent store", "Add 'Windows Remote Management' rules"))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Adding 'Windows Remote Management' firewall rules"

			Copy-NetFirewallRule -PolicyStore SystemDefaults -Group $WinRMRules `
				-Direction Inbound -NewPolicyStore PersistentStore |
			Set-NetFirewallRule -RemoteAddress Any | Enable-NetFirewallRule
		}
	}

	if (!(Get-NetFirewallRule -Group $WinRMCompatibilityRules -PolicyStore PersistentStore -EA Ignore))
	{
		if ($PSCmdlet.ShouldProcess("Windows firewall, persistent store", "Add 'Windows Remote Management - Compatibility Mode' rules"))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Adding 'Windows Remote Management - Compatibility Mode' firewall rules"

			Copy-NetFirewallRule -PolicyStore SystemDefaults -Group $WinRMCompatibilityRules `
				-Direction Inbound -NewPolicyStore PersistentStore |
			Set-NetFirewallRule -RemoteAddress Any | Enable-NetFirewallRule
		}
	}

	# TODO: Handled by Initialize-Service
	if ($WinRM.StartType -ne [ServiceStartMode]::Automatic)
	{
		if ($PSCmdlet.ShouldProcess($WinRM.DisplayName, "Set service to automatic startup"))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting $($WinRM.DisplayName) service to automatic startup"
			Set-Service -InputObject $WinRM -StartupType Automatic
		}
	}

	if ($WinRM.Status -ne [ServiceControllerStatus]::Running)
	{
		if ($PSCmdlet.ShouldProcess($WinRM.DisplayName, "Start service"))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Starting $($WinRM.DisplayName) service"
			$WinRM.Start()
			$WinRM.WaitForStatus([ServiceControllerStatus]::Running, $ServiceTimeout)
		}
	}
}
