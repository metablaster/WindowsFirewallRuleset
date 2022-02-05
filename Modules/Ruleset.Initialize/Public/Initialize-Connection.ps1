
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022 metablaster zebal@protonmail.ch

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
Initialize connection for firewall deployment

.DESCRIPTION
Initialize-Connection configures PowerShell for remote firewall deployment.
CIM session, PS session, remote registry etc.

.PARAMETER Force
The description of Force parameter.

.EXAMPLE
PS> Initialize-Connection

.INPUTS
None. You cannot pipe objects to Initialize-Connection

.OUTPUTS
None. Initialize-Connection does not generate any output

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Connection.md
#>
function Initialize-Connection
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium", PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Connection.md")]
	[OutputType([void])]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	# Establish WinRM connection to local or remote computer
	if ($PSCmdlet.ShouldProcess($PolicyStore, "Connect to remote computer and enable remote registry") -and
		!(Get-Variable -Name SessionEstablished -Scope Script -ErrorAction Ignore))
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Establishing session to remote computer"
		# NOTE: Global object RemoteRegistry (PSDrive), RemoteCim (CimSession) and RemoteSession (PSSession) are created by Connect-Computer function
		# NOTE: Global variable CimServer is set by Connect-Computer function
		# Destruction of these is done by Disconnect-Computer

		$ConnectParams = @{
			ErrorAction = "Stop"
			Domain = $PolicyStore
			Protocol = $RemotingProtocol
			ConfigurationName = $PSSessionConfigurationName
			ApplicationName = $PSSessionApplicationName
		}

		# PSPrimitiveDictionary, data to send to remote computer
		$SenderArguments = @{
			Domain = $PolicyStore
		}

		$SessionOptionParams = @{
			UICulture = $DefaultUICulture
			Culture = $DefaultCulture
			OpenTimeout = 3000
			CancelTimeout = 5000
			OperationTimeout = 10000
			MaxConnectionRetryCount = 2
			ApplicationArguments = $SenderArguments
			NoEncryption = $false
			NoCompression = $false
		}

		$PolicyStoreStatus = $false
		if ($PolicyStore -notin $LocalStore)
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Establishing session to remote computer"

			if ($PSVersionTable.PSEdition -eq "Core")
			{
				# Loopback WinRM is required for Ruleset.Compatibility module
				Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Checking if loopback WinRM requires configuration..."
				Test-WinRM -Protocol HTTP -Status ([ref] $PolicyStoreStatus) -Quiet

				if (!$PolicyStoreStatus)
				{
					# Enable loopback only HTTP
					Enable-WinRMServer -Protocol HTTP -KeepDefault -Loopback -Confirm:$false
					Test-WinRM -Protocol HTTP -Status ([ref] $PolicyStoreStatus) -ErrorAction Stop
				}
			}

			Set-Variable -Name RemotingCredential -Scope Global -Force -Value (
				Get-Credential -Message "Credentials are required to access '$PolicyStore'"
			)

			if (!$RemotingCredential)
			{
				# Will happen if credential request was dismissed using ESC key.
				Write-Error -Category InvalidOperation -Message "Credentials are required for remote session on '$Domain'"
			}
			elseif ($RemotingCredential.Password.Length -eq 0)
			{
				# Will happen when no password is specified
				Write-Error -Category InvalidData -Message "User '$($RemotingCredential.UserName)' must have a password"
				Set-Variable -Name RemotingCredential -Scope Global -Force -Value $null
			}

			$ConnectParams["Credential"] = $RemotingCredential

			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Checking if WinRM requires configuration..."
			Test-WinRM -Protocol $RemotingProtocol -Domain $PolicyStore -Credential $RemotingCredential -Status ([ref] $PolicyStoreStatus) -Quiet

			# TODO: A new function needed to conditionally configure remote host here
			if (!$PolicyStoreStatus)
			{
				# Configure this machine for remote session over SSL
				if ($RemotingProtocol -eq "HTTPS")
				{
					Set-WinRMClient -Protocol $RemotingProtocol -Domain $PolicyStore -Confirm:$false
				}
				else
				{
					Set-WinRMClient -Protocol $RemotingProtocol -Domain $PolicyStore -Confirm:$false -TrustedHosts $PolicyStore
				}

				Test-WinRM -Protocol $RemotingProtocol -Domain $PolicyStore -Credential $RemotingCredential -Status ([ref] $PolicyStoreStatus) -ErrorAction Stop
			}

			if (!(Test-RemoteRegistry -Domain $PolicyStore -Quiet))
			{
				Enable-RemoteRegistry -Confirm:$false
				Test-RemoteRegistry -Domain $PolicyStore
			}

			# TODO: Encoding, the acceptable values for this parameter are: Default, Utf8, or Utf16
			# There is global variable that controls encoding, see if it can be used here
			if ($RemotingProtocol -eq "HTTP")
			{
				$ConnectParams["CimOptions"] = New-CimSessionOption -Protocol Wsman -UICulture $DefaultUICulture -Culture $DefaultCulture
			}
			else
			{
				$ConnectParams["CimOptions"] = New-CimSessionOption -UseSsl -Encoding "Default" -UICulture $DefaultUICulture -Culture $DefaultCulture
			}
		}
		elseif ($PolicyStore -eq [System.Environment]::MachineName)
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Establishing session to local computer"
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Checking if WinRM requires configuration..."
			Test-WinRM -Protocol HTTP -Status ([ref] $PolicyStoreStatus) -Quiet

			if (!$PolicyStoreStatus)
			{
				# Enable loopback only HTTP
				Set-WinRMClient -Protocol HTTP -Confirm:$false
				Enable-WinRMServer -Protocol HTTP -KeepDefault -Loopback -Confirm:$false
				Test-WinRM -Protocol HTTP -Status ([ref] $PolicyStoreStatus) -ErrorAction Stop
			}

			$SessionOptionParams["NoEncryption"] = $true
			$SessionOptionParams["NoCompression"] = $true

			$ConnectParams["Protocol"] = "HTTP"
			$ConnectParams["CimOptions"] = New-CimSessionOption -Protocol Wsman -UICulture $DefaultUICulture -Culture $DefaultCulture
		}
		else
		{
			Write-Error -Category NotImplemented -TargetObject $PolicyStore -EA Stop `
				-Message "Deployment to specified policy store not implemented '$PolicyStore'"
		}

		# TODO: Not all options are used, ex. -NoCompression and -NoEncryption could be used for loopback
		$ConnectParams["SessionOption"] = New-PSSessionOption @SessionOptionParams

		try
		{
			Connect-Computer @ConnectParams

			# Check if session is already initialized and established, do not modify!
			# TODO: Connect-Computer may fail without throwing
			Set-Variable -Name SessionEstablished -Scope Script -Value $true
		}
		catch
		{
			Write-Error -ErrorRecord $_ -ErrorAction Stop
		}
	}
}
