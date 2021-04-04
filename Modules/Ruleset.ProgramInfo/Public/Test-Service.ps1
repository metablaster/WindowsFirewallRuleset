
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

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

.PARAMETER Force
If specified, lack of digital signature or signature mismatch produces a warning
instead of an error resulting in passed test.

.EXAMPLE
PS> Test-Service dnscache

.EXAMPLE
PS> @("msiserver", "Spooler", "WSearch") | Test-Service

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
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-Service.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[Alias("ServiceName")]
		[SupportsWildcards()]
		[ValidateScript( { $_ -ne "System.ServiceProcess.ServiceController" } )]
		[string[]] $Name,

		[Parameter()]
		[switch] $Force
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		# Keep track of already checked service signatures
		[hashtable] $BinaryPathCache = @{}
	}
	process
	{
		$Services = Get-Service -Name $Name -ErrorAction Ignore

		if (!$Services)
		{
			Write-Warning -Message "Service '$Name' was not found, rules for '$Name' service won't have any effect"
			Write-Information -Tags "User" -MessageData "INFO: To fix this problem, update or comment out all firewall rules for '$Name' service"
			return $false
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
				# TODO: This should probably be updated for remote computer
				$BinaryPath = Get-CimInstance -CimSession $RemoteCIM -Namespace "root\cimv2" `
					-Class Win32_Service -Property Name, PathName -Filter "Name = '$($Service.Name)'" |
				Select-Object -ExpandProperty PathName
			}

			if ([string]::IsNullOrEmpty($BinaryPath))
			{
				return $false
			}

			# regex out ex. "C:\WINDOWS\system32\svchost.exe -k netsvcs -p"
			$Executable = [regex]::Match($BinaryPath.TrimStart('"'), ".+(?=\.exe)")

			if ($Executable.Success)
			{
				$BinaryPath = $Executable.Value + ".exe"

				if ($BinaryPathCache["$BinaryPath"])
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Signature already checked for service binary '$BinaryPath'"
					Write-Output $true
					continue
				}

				# [System.Management.Automation.Signature]
				$Signature = Get-AuthenticodeSignature -LiteralPath $BinaryPath

				if ($Signature -and (($Signature.Status -eq "Valid") -or $Force))
				{
					if ($Signature.Status -ne "Valid")
					{
						Write-Warning -Message "Digital signature verification failed for service '$($Service.Name)'"
						Write-Information -Tags "User" -MessageData "INFO: $($Signature.StatusMessage)"
					}
					else
					{
						Write-Verbose -Message "[$($MyInvocation.InvocationName)] Service '$($Service.Name)' $($Signature.StatusMessage)"
					}

					$BinaryPathCache.Add($BinaryPath, $true)
					Write-Output $true
					continue
				}
				else
				{
					Write-Error -Category SecurityError -TargetObject $LiteralPath `
						-Message "Digital signature verification failed for service '$($Service.Name)'"
					Write-Information -Tags "User" -MessageData "INFO: $($Signature.StatusMessage)"
				}
			}
			elseif ($Signature) # else Get-AuthenticodeSignature should show the error (ex. file not found)
			{
				Write-Error -Category InvalidResult -TargetObject $Service `
					-Message "Unable to determine binary path for '$($Service.Name)' service"
			}

			Write-Output $false
			continue
		} # foreach
	}
}
