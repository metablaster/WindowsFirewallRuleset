
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2022 metablaster zebal@protonmail.ch

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
Check if system service exists and is trusted

.DESCRIPTION
Test-Service verifies specified Windows services exists.
The service is then verified to confirm it's digitaly signed and that signature is valid.
If the service can't be found or verified, an error is genrated.

.PARAMETER Name
Service short name (not display name)

.PARAMETER Domain
Computer name on which service to be tested is located

.PARAMETER Credential
Specifies the credential object to use for authentication

.PARAMETER Session
Specifies the PS session to use

.PARAMETER SigcheckLocation
Specify path to sigcheck executable program.
Do not specify sigcheck file, only path to where sigcheck is located.
By default working directory and PATH is searched for sigcheck64.exe.
On 32 bit operating system sigcheck.exe is searched instead.
If location to sigcheck executable is not found then no VirusTotal scan and report is done.

.PARAMETER Timeout
Specify maximum wait time expressed in seconds for VirusTotal to scan individual file.
Value 0 means an immediate return, and a value of -1 specifies an infinite wait.
The default wait time is 300 (5 minutes).

.PARAMETER Quiet
If specified, no information, warning or error message is shown, only true or false is returned

.PARAMETER Force
If specified, lack of digital signature or signature mismatch produces a warning
instead of an error resulting in passed test.

.EXAMPLE
PS> Test-Service dnscache

.EXAMPLE
PS> Test-Service WSearch -Domain Server01

.EXAMPLE
PS> Test-Service SomeService -Quiet -Force

.INPUTS
[string[]]

.OUTPUTS
[bool]

.NOTES
TODO: Implement accept ServiceController object, should be called InputObject, a good design needed,
however it doesn't make much sense since the function is to test existence of a service too.
#>
function Test-Service
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Domain",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-Service.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[Alias("ServiceName")]
		[SupportsWildcards()]
		[ValidateScript( { $_ -ne "System.ServiceProcess.ServiceController" } )]
		[string] $Name,

		[Parameter(ParameterSetName = "Domain")]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter(ParameterSetName = "Domain")]
		[PSCredential] $Credential,

		[Parameter(ParameterSetName = "Session")]
		[System.Management.Automation.Runspaces.PSSession] $Session,

		[Parameter()]
		[System.IO.DirectoryInfo] $SigcheckLocation = $SigcheckPath,

		[Parameter()]
		[ValidateRange(1, 650)]
		[int32] $TimeOut = 300,

		[Parameter()]
		[switch] $Quiet,

		[Parameter()]
		[switch] $Force
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	[hashtable] $SessionParams = @{}
	if ($PsCmdlet.ParameterSetName -eq "Session")
	{
		$Domain = $Session.ComputerName
		$SessionParams.Session = $Session
	}
	else
	{
		$Domain = Format-ComputerName $Domain

		# Avoiding NETBIOS ComputerName for localhost means no need for WinRM to listen on HTTP
		if ($Domain -ne [System.Environment]::MachineName)
		{
			$SessionParams.ComputerName = $Domain
			if ($Credential)
			{
				$SessionParams.Credential = $Credential
			}
		}
	}

	if ($Quiet)
	{
		$ErrorActionPreference = "SilentlyContinue"
		$WarningPreference = "SilentlyContinue"
		$InformationPreference = "SilentlyContinue"
	}

	# Keep track of already checked service signatures
	[hashtable] $BinaryPathCache = @{}

	$Services = Invoke-Command @SessionParams -ArgumentList $Name -ScriptBlock {
		Get-Service -Name $args[0] -ErrorAction Ignore
	}

	if (!$Services)
	{
		Write-Warning -Message "[$($MyInvocation.InvocationName)] Service '$Name' was not found or could not be resolved, rules for '$Name' service won't have any effect"
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: To silence this warning, update or comment out all firewall rules for '$Name' service"
	}

	foreach ($Service in $Services)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Testing service '$($Service.DisplayName)'"

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			$BinaryPath = $Service.BinaryPathName
		}
		else
		{
			# HACK: Duplicate of PSSession parameter
			$BinaryPath = Get-CimInstance -CimSession $CimServer -Namespace "root\cimv2" `
				-Class Win32_Service -Property Name, PathName -Filter "Name = '$($Service.Name)'" |
			Select-Object -ExpandProperty PathName
		}

		if ([string]::IsNullOrEmpty($BinaryPath))
		{
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Binary path of the service '$($Service.Name)' was not found"
			Write-Output $false
			continue
		}

		# regex out ex. "C:\WINDOWS\system32\svchost.exe -k netsvcs -p"
		$Executable = [regex]::Match($BinaryPath.TrimStart('"'), ".+(?=\.exe)")

		if ($Executable.Success)
		{
			$BinaryPath = $Executable.Value + ".exe"
			if ($BinaryPathCache[$BinaryPath])
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Signature already checked for service binary '$BinaryPath'"
				Write-Output $true
				continue
			}

			# [System.Management.Automation.Signature]
			$Signature = Invoke-Command @SessionParams -ArgumentList $BinaryPath -ScriptBlock {
				Get-AuthenticodeSignature -LiteralPath $args[0]
			}

			if ($Signature.Status -ne "Valid")
			{
				if ($Force)
				{
					Write-Warning -Message "[$($MyInvocation.InvocationName)] Digital signature verification failed for service '$($Service.Name)'"
					$BinaryPathCache.Add($BinaryPath, $true)

					if (Test-VirusTotal -LiteralPath $BinaryPath -SigcheckLocation $SigcheckLocation -TimeOut $TimeOut @SessionParams)
					{
						Write-Output $false
						continue
					}

					Write-Output $true
					continue
				}
				else
				{
					Write-Error -Category SecurityError -TargetObject $BinaryPath `
						-Message "Digital signature verification failed for service '$($Service.Name)'"
					Test-VirusTotal -LiteralPath $BinaryPath -SigcheckLocation $SigcheckLocation -TimeOut $TimeOut @SessionParams | Out-Null
				}
			}
			else
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Service '$($Service.Name)' $($Signature.StatusMessage)"

				$BinaryPathCache.Add($BinaryPath, $true)
				Write-Output $true
				continue
			}
		}
		else
		{
			Write-Error -Category InvalidResult -TargetObject $Service `
				-Message "Unable to determine binary path for '$($Service.Name)' service"
		}

		Write-Output $false
		continue
	} # foreach service
}
