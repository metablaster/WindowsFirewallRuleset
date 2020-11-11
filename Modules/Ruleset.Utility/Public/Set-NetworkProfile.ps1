
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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
Set network profile for physical network interfaces

.DESCRIPTION
Set network profile for each physical/hardware network interfaces
Recommended is 'Public' profile for maximum security, unless 'Private' is needed

.EXAMPLE
PS> Set-NetworkProfile

.INPUTS
None. You cannot pipe objects to Set-NetworkProfile

.OUTPUTS
None. Set-NetworkProfile does not generate any output

.NOTES
TODO: It looks like option to change network profile in settings app will be gone after using this
function in an elevated prompt
#>
function Set-NetworkProfile
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Set-NetworkProfile.md")]
	[OutputType([void])]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	if ($PSCmdlet.ShouldProcess("Configure network profile"))
	{
		[string[]] $HardwareInterfaces = Get-NetConnectionProfile |
		Select-Object -ExpandProperty InterfaceAlias

		# Interface could be null
		# TODO: When could second check be true? (interfaces -eq 0)
		if (!$HardwareInterfaces -or ($HardwareInterfaces.Length -eq 0))
		{
			# TODO: we should base this on IPv*Connectivity given by Get-NetConnectionProfile
			Write-Warning -Message "Unable to set network profile, machine not connected to network"
			return
		}

		# NOTE: not logging this warning
		Write-Warning -Message "For maximum security choose 'Public' network profile"

		foreach ($Interface in $HardwareInterfaces)
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing $Interface"

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
				$NetworkCategory = "Public"
			}
			elseif ($Decision -eq 1)
			{
				$NetworkCategory = "Private"
			}
			else
			{
				Write-Warning -Message "The operation has been canceled by the user"
				return
			}

			Set-NetConnectionProfile -InterfaceAlias $Interface -NetworkCategory $NetworkCategory
			Write-Information -Tags "User" -MessageData "INFO: Network profile set to '$NetworkCategory' for '$Interface' interface"
		}
	}
	else
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] User refused setting network profile"
	}
}
