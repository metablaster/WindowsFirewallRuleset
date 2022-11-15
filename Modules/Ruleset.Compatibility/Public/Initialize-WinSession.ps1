
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2018, 2019 Microsoft Corporation. All rights reserved

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
Initialize the connection to the compatibility session

.DESCRIPTION
Initialize the connection to the compatibility session.
By default the compatibility session will be created on the localhost using the "Microsoft.PowerShell" configuration.
On subsequent calls, if a session matching the current specification is found,
it will be returned rather than creating a new session.
If a matching session is found, but can't be used,
it will be closed and a new session will be retrieved.

This command is called by the other commands in this module so you will rarely call this command directly.

.PARAMETER Domain
If you don't want to use the default compatibility session, use this parameter to specify the name
of the computer on which to create the compatibility session.

.PARAMETER ConfigurationName
Specifies the configuration to connect to when creating the compatibility session
(Defaults to "Microsoft.PowerShell")

.PARAMETER Credential
The credential to use when connecting to the target machine/configuration

.PARAMETER PassThru
If present, the specified session object will be returned

.EXAMPLE
PS> Initialize-WinSession

Initialize the default compatibility session.

.EXAMPLE
PS> Initialize-WinSession -Domain localhost -ConfigurationName Microsoft.PowerShell

Initialize the compatibility session with a specific computer name and configuration

.INPUTS
None. You cannot pipe objects to Initialize-WinSession

.OUTPUTS
[System.Management.Automation.Runspaces.PSSession]

.NOTES
Following modifications by metablaster November 2020:

- Added comment based help based on original comments
- Code formatting according to the rest of project design
- Added HelpURI link to project location

January 2021:

- Added parameter debugging stream

February 2022:
Added check to confirm session configuration is present and enabled
Added logic to convert local computer name to localhost

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Initialize-WinSession.md

.LINK
https://github.com/PowerShell/WindowsCompatibility
#>
function Initialize-WinSession
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Initialize-WinSession.md")]
	[OutputType([System.Management.Automation.Runspaces.PSSession])]
	Param (
		[Parameter(Position = 0)]
		[Alias("ComputerName", "CN")]
		[string] $Domain,

		[Parameter()]
		[string] $ConfigurationName,

		[Parameter()]
		[PSCredential] $Credential,

		[Parameter()]
		[switch] $PassThru
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if (($Domain -eq ".") -or ($Domain -eq [System.Environment]::MachineName))
	{
		# NOTE: Setting $Domain to default to "[System.Environment]::MachineName" would require a WinRM listener on local IP address
		$Domain = "localhost"
	}

	if ([string]::IsNullOrEmpty($Domain))
	{
		$Domain = $script:SessionComputerName
	}
	else
	{
		$script:SessionComputerName = $Domain
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Initializing the compatibility session on computer '$Domain'"

	if ([string]::IsNullOrEmpty($ConfigurationName))
	{
		$ConfigurationName = $script:SessionConfigurationName
	}
	else
	{
		$script:SessionConfigurationName = $ConfigurationName
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Using '$ConfigurationName' configuration for compatibility session"

	# Confirm specified session configuration is present and enabled in Windows PowerShell
	$Command = "Get-PSSessionConfiguration -Name $ConfigurationName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Enabled"
	$SessionAvailable = & C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -Command $Command

	if (!$SessionAvailable -or ($SessionAvailable -eq $false))
	{
		Write-Error -Category ResourceUnavailable -TargetObject $ConfigurationName `
			-Message "[$($MyInvocation.InvocationName)] Please enable '$ConfigurationName' session in Windows PowerShell in order for Ruleset.Compatibility module to work"
		return
	}

	if ($Credential)
	{
		$script:SessionName = "Ruleset.Compatibility-$Domain-$($Credential.UserName)"
	}
	else
	{
		$script:SessionName = "Ruleset.Compatibility-$Domain-$([System.Environment]::UserName)"
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] The compatibility session name is '$script:SessionName'"

	$Session = Get-PSSession | Where-Object {
		($_.ComputerName -eq $Domain) -and
		($_.ConfigurationName -eq $ConfigurationName) -and
		($_.Name -eq $script:SessionName)
	} | Select-Object -First 1

	# Deal with the possibilities of multiple sessions.
	# This might arise from the user hitting ctrl-C.
	# We'll make the assumption that the first one returned is the correct one and we'll remove the rest.
	# TODO: This needs to be tested, ex. Select-Object -First 1 should be removed
	$Session, $Rest = $Session
	if ($Rest)
	{
		foreach ($Entry in $Rest)
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Removing stale compatibility session '$Entry'"
			Remove-PSSession $Entry
		}
	}

	if ($Session -and ($Session.State -ne "Opened"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Removing closed compatibility session"
		Remove-PSSession $Session
		$Session = $null
	}

	if (!$Session)
	{
		$PSSessionParams = @{
			ComputerName = $Domain
			Name = $script:SessionName
			ConfigurationName = $ConfigurationName
			ErrorAction = "Stop"
		}

		if ($Credential)
		{
			$PSSessionParams.Credential = $Credential
		}

		if ($Domain -eq "localhost")
		{
			# MSDN: EnableNetworkAccess, indicates that this cmdlet adds an interactive security token to loopback sessions.
			# The interactive token lets you run commands in the loopback session that get data from other computers
			# The EnableNetworkAccess parameter is effective only in loopback sessions.
			$PSSessionParams.EnableNetworkAccess = $true
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating new compatibility session on computer '$Domain'"

		# NOTE: This will fail with "access denied" if session configuration was disabled in Windows PowerShell,
		# ex. by using Reset-Firewall -Remote, see Remote.md for fix
		# TODO: Will create a new blank console windows in PS Core, see also Connect-Computer
		$Session = New-PSSession @PSSessionParams -EV test | Select-Object -First 1

		# keep the compatibility session PWD in sync with the parent PWD.
		# This only applies on localhost.
		if ($Session.ComputerName -eq "localhost")
		{
			# TODO: Why is this needed?
			$UsingPath = (Get-Location).Path
			Invoke-Command -Session $Session -ScriptBlock { Set-Location $using:usingPath }
		}
	}
	else
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Reusing the existing compatibility session, 'computer = $script:SessionComputerName'"
	}

	if ($PassThru)
	{
		return $Session
	}
}
