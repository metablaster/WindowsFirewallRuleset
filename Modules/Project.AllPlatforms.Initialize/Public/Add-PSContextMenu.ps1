
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 metablaster zebal@protonmail.ch

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
Add Windows PowerShell context menu to shell (right click)

.DESCRIPTION
Add-PSContextMenu adds Windows shell context menu on right click for "Windows PowerShell"
In addition to the context menu which can be as well set manually, the purpose of this
function is to deploy context menu on fresh install system as part of project development setup.

.PARAMETER Admin
If specified adds PowerShell context item to be run as Administrator.
By default PowerShell context item is to be run as standard user.

.PARAMETER Shift
If specified, requires SHIFT right click to show PowerShell context menu item.
By default only right click is required.

.EXAMPLE
PS> Add-PSContextMenu -Shift

Adds Windows PowerShell context menu on SHIFT + right click for run as standard user

.EXAMPLE
PS> Add-PSContextMenu -Admin

Adds Windows PowerShell context menu on right click for run as Administrator

.INPUTS
None. You cannot pipe objects to Add-PSContextMenu

.OUTPUTS
None. Add-PSContextMenu does not generate any output

.NOTES
TODO: Add-PSContextMenu is under construction

.LINK
https://www.tenforums.com/tutorials/60175-open-powershell-window-here-context-menu-add-windows-10-a.html

.LINK
https://www.tenforums.com/tutorials/60177-add-open-powershell-window-here-administrator-windows-10-a.html
#>
function Add-PSContextMenu
{
	[OutputType([void])]
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.AllPlatforms.Initialize/Help/en-US/Add-PSContextMenu.md")]
	param (
		[Parameter()]
		[switch] $Admin,

		[Parameter()]
		[switch] $Shift
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	if ($PSCmdlet.ShouldProcess("Windows registry", "Add Windows PowerShell context menu"))
	{
		if (!$Admin)
		{
			# Ownership + Full control
			$TargetKeys = @(
				"Directory\shell\Powershell"
				"Directory\shell\Powershell\command"
				"Directory\Background\shell\Powershell"
				"Directory\Background\shell\Powershell\command"
				"Drive\shell\Powershell"
				"Drive\shell\Powershell\command"
			)

			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening registry hive"
			$RegistryHive = [Microsoft.Win32.RegistryHive]::ClassesRoot
			$RootKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey($RegistryHive)

			if (!$RootKey)
			{
				Write-Warning -Message "Failed to open registry root key: $RegistryHive"
				return
			}

			foreach ($Key in $TargetKeys)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: $Key"
				$SubKey = $RootKey.OpenSubkey($Key)

				if ($SubKey)
				{
					# Take ownership and set full control
					Set-Permission -Owner "Administrators" -Path $SubKey.Name
					Set-Permission -Principal "Administrators" -Path $SubKey.Name -RegGrant "FullControl"
				}
				else
				{
					Write-Warning -Message "Failed to open registry sub key: $HKLMSubKey"
					continue
				}

				# Restore defaults
				Set-Permission -Path $SubKey.Name -Reset
				Set-Permission -Owner "TrustedInstaller" -Domain "NT SERVICE" -Path $SubKey.Name
			}
		}
	}
}
