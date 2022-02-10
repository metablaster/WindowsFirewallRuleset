
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

	[bool] $VerboseFlag = $PSBoundParameters["Verbose"]

	if ($Domain -eq ".")
	{
		$Domain = "localhost"
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Initializing the compatibility session on host '$Domain'."

	if ($Domain)
	{
		$script:SessionComputerName = $Domain
	}
	else
	{
		$Domain = $script:SessionComputerName
	}

	if ($ConfigurationName)
	{
		$script:SessionConfigurationName = $ConfigurationName
	}
	else
	{
		$ConfigurationName = $script:SessionConfigurationName
	}

	# Confirm specified session configuration is present and enabled
	$Command = "Get-PSSessionConfiguration -Name $ConfigurationName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Enabled"
	$SessionAvailable = & C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe $Command
	if (!$SessionAvailable -or ($SessionAvailable -eq "False"))
	{
		Write-Error -Category ResourceUnavailable -TargetObject $ConfigurationName `
			-Message "[$($MyInvocation.InvocationName)] Please enable '$ConfigurationName' session in Windows PowerShell in order for Ruleset.Compatibility module to work"
		return
	}

	if ($Credential)
	{
		$script:SessionName = "wincompat-$Domain-$($Credential.UserName)"
	}
	else
	{
		$script:SessionName = "wincompat-$Domain-$([System.Environment]::UserName)"
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] The compatibility session name is '$script:SessionName'."

	$Session = Get-PSSession | Where-Object {
		$_.ComputerName -eq $Domain -and
		$_.ConfigurationName -eq $ConfigurationName -and
		$_.Name -eq $script:SessionName
	} | Select-Object -First 1

	# Deal with the possibilities of multiple sessions. This might arise
	# from the user hitting ctrl-C. We'll make the assumption that the
	# first one returned is the correct one and we'll remove the rest.
	$Session, $Rest = $Session
	if ($Rest)
	{
		foreach ($Entry in $Rest)
		{
			Remove-PSSession $Entry
		}
	}

	if ($Session -and $Session.State -ne "Opened")
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Removing closed compatibility session."
		Remove-PSSession $Session
		$Session = $null
	}

	if (!$Session)
	{
		$NewPSSessionParameters = @{
			Verbose = $VerboseFlag
			ComputerName = $Domain
			Name = $script:SessionName
			ConfigurationName = $ConfigurationName
			ErrorAction = "Stop"
		}

		if ($Credential)
		{
			$NewPSSessionParameters.Credential = $Credential
		}

		if ($Domain -eq "localhost" -or $Domain -eq [System.Environment]::MachineName)
		{
			$NewPSSessionParameters.EnableNetworkAccess = $true
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Created new compatibility session on host '$Domain'"
		$Session = New-PSSession @NewPSSessionParameters | Select-Object -First 1

		if ($Session.ComputerName -eq "localhost")
		{
			$UsingPath = (Get-Location).Path
			Invoke-Command $Session -ScriptBlock { Set-Location $using:usingPath }
		}
	}
	else
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Reusing the existing compatibility session; 'host = $script:SessionComputerName'."
	}

	if ($PassThru)
	{
		return $Session
	}
}
