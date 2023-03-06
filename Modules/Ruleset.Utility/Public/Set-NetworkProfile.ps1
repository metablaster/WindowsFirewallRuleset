
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2023 metablaster zebal@protonmail.ch

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

using namespace System.Management.Automation.Host

<#
.SYNOPSIS
Set network profile on connected network interfaces

.DESCRIPTION
Set network profile for each connected network interface.
Recommended is "Public" profile for maximum security, unless "Private" is needed.

.PARAMETER NetworkCategory
Specify network category which to apply to all NIC's.
If not specified, you're prompted for each NIC individually

.PARAMETER Domain
Computer name on which to set network profile

.PARAMETER Credential
Specify Credential used for authentication to Domain.

.PARAMETER Session
Specifies the PS session to use

.EXAMPLE
PS> Set-NetworkProfile

.EXAMPLE
PS> Set-NetworkProfile Public

.INPUTS
None. You cannot pipe objects to Set-NetworkProfile

.OUTPUTS
None. Set-NetworkProfile does not generate any output

.NOTES
None.
#>
function Set-NetworkProfile
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High", DefaultParameterSetName = "None",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Set-NetworkProfile.md")]
	[OutputType([void])]
	param (
		[Parameter()]
		[ValidateSet("Public", "Domain", "Private")]
		[string] $NetworkCategory,

		[Parameter(ParameterSetName = "Domain")]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter(ParameterSetName = "Domain")]
		[PSCredential] $Credential,

		[Parameter(ParameterSetName = "Session")]
		[System.Management.Automation.Runspaces.PSSession] $Session
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	[hashtable] $SessionParams = @{}
	if ($PSCmdlet.ParameterSetName -eq "Session")
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

	if ($PSCmdlet.ShouldProcess("Each network interface on '$Domain' computer", "Configure network profile"))
	{
		[string[]] $HardwareInterfaces = Invoke-Command @SessionParams -ScriptBlock {

			# NOTE: This will include external switches bound to physical adapters as well
			Get-NetConnectionProfile |
			Select-Object -ExpandProperty InterfaceAlias
		}

		# Interface could be null
		# TODO: In which case could second check be true? (interfaces -eq 0)
		if (!$HardwareInterfaces -or ($HardwareInterfaces.Length -eq 0))
		{
			# TODO: We should base this on IPv*Connectivity given by Get-NetConnectionProfile
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Unable to set network profile, '$Domain' computer not connected to network"
			return
		}

		foreach ($Interface in $HardwareInterfaces)
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing $Interface"

			if ($NetworkCategory)
			{
				$Category = $NetworkCategory
			}
			else
			{
				# User prompt default values
				[int32] $Default = 0
				[ChoiceDescription[]] $Choices = @()
				$Public = [ChoiceDescription]::new("&Public")
				$Private = [ChoiceDescription]::new("P&rivate")
				$Abort = [ChoiceDescription]::new("&Abort")

				$Public.HelpMessage = "Your PC is hidden from other devices on the network"
				$Private.HelpMessage = "Your PC is discoverable and can be used for file and printer sharing"
				$Abort.HelpMessage = "Abort operation, no change is done to network profile"

				$Choices += $Public
				$Choices += $Private
				$Choices += $Abort

				$Title = "Choose network profile"
				$Question = "Which network profile to set for '$Interface' interface?"
				$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

				if ($Decision -eq 0)
				{
					$Category = "Public"
				}
				elseif ($Decision -eq 1)
				{
					$Category = "Private"
				}
				else
				{
					Write-Warning -Message "[$($MyInvocation.InvocationName)] The operation has been canceled by the user"
					return
				}
			}

			Invoke-Command @SessionParams -ArgumentList $MyInvocation.InvocationName, $Category, $Interface, $Domain -ScriptBlock {
				param (
					$InvocationName,
					$Category,
					$Interface,
					$Domain
				)

				Set-NetConnectionProfile -InterfaceAlias $Interface -NetworkCategory $Category
				Write-Information -Tags $InvocationName `
					-MessageData "INFO: Network profile set to '$Category' for '$Interface' interface on '$Domain' computer"
			}
		}
	}
	else
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting network profile skipped by user"
	}
}
