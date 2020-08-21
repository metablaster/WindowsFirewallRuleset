
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
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
Get a list of module names that can be updated
.DESCRIPTION
Get a list of module names that can be updated, the list of modules can then be used for
Update-Help to minimize Update-Help errors
.PARAMETER Module
Optional list of module names for which to check if they can be updated
If not specified all available modules on system are checked
.EXAMPLE
PS> Find-UpdatableModule

PackageManagement
PowerShellGet
CimCmdlets
Microsoft.PowerShell.Archive
PSDesiredStateConfiguration
.INPUTS
[string[]] one or multiple module names to check
.OUTPUTS
[string[]] list of module names ready for update
.NOTES
None.
#>
function Find-UpdatableModule
{
	[OutputType([string[]])]
	[CmdletBinding()]
	Param(
		[Parameter(ValueFromPipeline = $true)]
		[string[]] $Module
	)

	begin
	{
		# https://docs.microsoft.com/en-us/powershell/scripting/developer/help/helpinfo-xml-schema?view=powershell-7
		$HelpInfoNamespace = @{ helpInfo = 'http://schemas.microsoft.com/powershell/help/2010/05' }

		[PSModuleInfo[]] $Modules = @()
		if ($Module)
		{
			$Modules = Get-Module -Name $Module -ListAvailable | Where-Object -Property HelpInfoUri
		}
		else
		{
			$Modules = Get-Module -ListAvailable | Where-Object -Property HelpInfoUri
		}

		if (!$Modules)
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] No modules found, aborting"
		}
	}
	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		[string[]] $ModuleList = @()

		foreach ($TargetModule in $Modules)
		{
			$HelpInfoFile = "$($TargetModule.ModuleBase)\*helpinfo.xml"

			if (Test-Path -PathType Leaf $HelpInfoFile)
			{
				$Nodes = Get-ChildItem $HelpInfoFile -ErrorAction SilentlyContinue |
				Select-Xml -Namespace $HelpInfoNamespace -XPath "//helpInfo:UICulture"

				foreach ($Node in $Nodes)
				{
					$ModuleList += $TargetModule.Name
				}
			}
		}

		if (!$ModuleList)
		{
			Write-Warning -Message "None of the input modules support help update"
		}

		Write-Output $ModuleList
	}
}
