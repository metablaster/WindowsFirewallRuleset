
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
Get modules that can be updated with no error

.DESCRIPTION
Find-UpdatableModule retrieves modules that can be updated without error,
the list of modules can then be used for Update-Help to minimize Update-Help errors
Without any parameters all available modules on system are checked

.PARAMETER Module
Optional list of module names for which to check if they can be updated

.PARAMETER FullyQualifiedName
Optional module to check in the form of ModuleSpecification object

.PARAMETER UICulture
Find updatable modules only for specified UI culture values

.EXAMPLE
PS> Find-UpdatableModule

PackageManagement
PowerShellGet
CimCmdlets
Microsoft.PowerShell.Archive
PSDesiredStateConfiguration

.EXAMPLE
PS> Find-UpdatableModule -FullyQualifiedName @{ ModuleName = "WindowsErrorReporting"; ModuleVersion = "1.0" }

Culture                        en-US
CultureVersion                 5.0.0.0
Name                           WindowsErrorReporting

.EXAMPLE
PS> @("PowerShellGet", "PackageManagement", "PSScriptAnalyzer") | Find-UpdatableModule

Culture                        en-US
CultureVersion                 5.2.0.0
Name                           PowerShellGet
Culture                        en-US
CultureVersion                 5.2.0.0
Name                           PackageManagement

.EXAMPLE
PS> Find-UpdatableModule "PowerShellGet" -UICulture ja-JP, en-US

Name                           Value
----                           -----
Culture                        en-US
CultureVersion                 5.2.0.0
Name                           PowerShellGet
Culture                        ja-JP
CultureVersion                 5.2.0.0
Name                           PowerShellGet

.INPUTS
[string[]] One or multiple module names to check
[hashtable] Fully qualified module name in the form of ModuleSpecification object

.OUTPUTS
[PSCustomObject] Module description object ready for help files update

.NOTES
This function main purpose is automated development environment setup to be able to perform quick
setup on multiple computers and virtual operating systems, in cases such as frequent system restores
for the purpose of testing project code for many environment scenarios that end users may have.
It should be used in conjunction with the rest of a module "Ruleset.Initialize"

TODO: test UICulture from pipeline
TODO: There can't be multiple inputs?
NOTE: Before running this function Update-Help must be run as Administrator once on target system to
download required helpinfo.xml files
#>
function Find-UpdatableModule
{
	[CmdletBinding(DefaultParameterSetName = "Name")]
	[OutputType([System.Management.Automation.PSCustomObject])]
	param (
		[Parameter(ValueFromPipeline = $true, ParameterSetName = "Name", Position = 0)]
		[string[]] $Module = $null,

		[Parameter(ValueFromPipeline = $true, ParameterSetName = "Full", Position = 0,
			HelpMessage = "Specify module to check in the form of ModuleSpecification object")]
		[hashtable] $FullyQualifiedName = $null,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = "Name")]
		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = "Full")]
		[ValidatePattern("^[a-z]{2}-[A-Z]{2}$")]
		[System.Globalization.CultureInfo[]] $UICulture
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		# https://docs.microsoft.com/en-us/powershell/scripting/developer/help/helpinfo-xml-schema?view=powershell-7
		$HelpInfoNamespace = @{ helpInfo = 'http://schemas.microsoft.com/powershell/help/2010/05' }

		[PSModuleInfo[]] $Modules = @()
	}
	process
	{
		if ($Module)
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Get-Module -Name"
			$Modules = Get-Module -ListAvailable -Name $Module | Where-Object -Property HelpInfoUri
		}
		elseif ($FullyQualifiedName)
		{
			# Validate module specification
			if ($FullyQualifiedName.Count -ge 2 -and
				($FullyQualifiedName.ContainsKey("ModuleName") -and $FullyQualifiedName.ContainsKey("ModuleVersion")))
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Get-Module -FullyQualifiedName"
				$Modules = Get-Module -ListAvailable -FullyQualifiedName $FullyQualifiedName | Where-Object -Property HelpInfoUri
			}
			else
			{
				Write-Error -Category InvalidArgument -TargetObject $FullyQualifiedName `
					-Message "ModuleSpecification parameter for: $($FullyQualifiedName.ModuleName) is not valid"
				return
			}
		}
		else
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Get-Module -ListAvailable"
			$Modules = Get-Module -ListAvailable | Where-Object -Property HelpInfoUri
		}

		if (!$Modules)
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] No candidate modules found, aborting"
		}

		foreach ($TargetModule in $Modules)
		{
			# Each module has separate xml help info files for each culture
			$InfoXMLFiles = "$($TargetModule.ModuleBase)\*"

			if (Test-Path -PathType Leaf $InfoXMLFiles)
			{
				$Nodes = Get-ChildItem -Path $InfoXMLFiles -Filter *helpinfo.xml -ErrorAction SilentlyContinue |
				Select-Xml -Namespace $HelpInfoNamespace -XPath "//helpInfo:UICulture"

				if ($UICulture)
				{
					foreach ($NodeInfo in $Nodes)
					{
						$CultureName = $NodeInfo.Node.UICultureName
						# Select only specified cultures
						if ($UICulture -contains $CultureName)
						{
							Write-Debug -Message "[$($MyInvocation.InvocationName)] Found culture $CultureName for module $($TargetModule.Name)"

							[PSCustomObject] @{
								Name = $TargetModule.Name
								Culture = $CultureName
								CultureVersion = $NodeInfo.Node.UICultureVersion
							}
						}
					}
				}
				else
				{
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Selecting all cultures"

					foreach ($NodeInfo in $Nodes)
					{
						# Select all cultures
						[PSCustomObject] @{
							Name = $TargetModule.Name
							Culture = $NodeInfo.Node.UICultureName
							CultureVersion = $NodeInfo.Node.UICultureVersion
						}
					}
				}
			}
		}
	}
}
