
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

.PARAMETER Force
If specified, does not prompt for confirmation.

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
	[CmdletBinding()]
	[OutputType([void])]
	param (
		[Parameter()]
		[switch] $Force
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	$VerbosePreference = "Continue"

	if ($Force -or $PSCmdlet.ShouldContinue("Windows firewall, persistent store", "Add 'Windows Remote Management' rules"))
	{
		# NOTE: "Windows Remote Management" predefined rules (including compatibility rules) if not
		# present may cause issues adjusting some of the WinRM options
		if (!(Get-NetFirewallRule -Group $WinRMRules -PolicyStore PersistentStore -EA Ignore))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Adding firewall rules 'Windows Remote Management'"

			Copy-NetFirewallRule -PolicyStore SystemDefaults -Group $WinRMRules `
				-Direction Inbound -NewPolicyStore PersistentStore |
			Set-NetFirewallRule -RemoteAddress Any | Enable-NetFirewallRule
		}

		if (!(Get-NetFirewallRule -Group $WinRMCompatibilityRules -PolicyStore PersistentStore -EA Ignore))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Adding firewall rules 'Windows Remote Management - Compatibility Mode'"

			Copy-NetFirewallRule -PolicyStore SystemDefaults -Group $WinRMCompatibilityRules `
				-Direction Inbound -NewPolicyStore PersistentStore |
			Set-NetFirewallRule -RemoteAddress Any | Enable-NetFirewallRule
		}
	}

	if ($Force -or $PSCmdlet.ShouldContinue("Windows Remote Management (WS-Management)", "Start service and set to automatic startup"))
	{
		# NOTE: WinRM service must be running at this point
		# TODO: Handled by ProjectSettings.ps1
		if ($WinRM.StartType -ne "Automatic")
		{
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Setting WS-Management service to automatic startup"
			Set-Service -InputObject $WinRM -StartType Automatic
		}

		if ($WinRM.Status -ne "Running")
		{
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Starting WS-Management service"
			$WinRM.Start()
			$WinRM.WaitForStatus("Running", $ServiceTimeout)
		}
	}
}
