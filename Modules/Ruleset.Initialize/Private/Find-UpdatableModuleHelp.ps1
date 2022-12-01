
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
Get modules for which help files can be updated without error

.DESCRIPTION
Find-UpdatableModuleHelp retrieves modules for which help files can be updated without error,
the list of modules can then be used for Update-Help to minimize Update-Help errors
Without any parameters all available modules on system are checked

.PARAMETER Name
Optional list of module names for which to check if they can be updated
Wildcard characters are supported.

.PARAMETER FullyQualifiedName
The value can be a module name, a full module specification, or a path to a module file.

When the value is a path, the path can be fully qualified or relative.
A relative path is resolved relative to the script that contains the using statement.

When the value is a name or module specification, PowerShell searches the PSModulePath for the specified module.
A module specification is a hashtable that has the following keys:

ModuleName - Required Specifies the module name.
GUID - Optional Specifies the GUID of the module.
It's also Required to specify at least one of the three below keys.
ModuleVersion - Specifies a minimum acceptable version of the module.
MaximumVersion - Specifies the maximum acceptable version of the module.
RequiredVersion - Specifies an exact, required version of the module. This can't be used with the other Version keys.

.PARAMETER UICulture
Find updatable modules only for the specified UI culture values

.EXAMPLE
PS> Find-UpdatableModuleHelp

PackageManagement
PowerShellGet
CimCmdlets
Microsoft.PowerShell.Archive
PSDesiredStateConfiguration

.EXAMPLE
PS> Find-UpdatableModuleHelp -FullyQualifiedName @{ ModuleName = "WindowsErrorReporting"; ModuleVersion = "1.0" }

Culture                        en-US
CultureVersion                 5.0.0.0
Name                           WindowsErrorReporting

.EXAMPLE
PS> @("PowerShellGet", "PackageManagement", "PSScriptAnalyzer") | Find-UpdatableModuleHelp

Culture                        en-US
CultureVersion                 5.2.0.0
Name                           PowerShellGet
Culture                        en-US
CultureVersion                 5.2.0.0
Name                           PackageManagement

.EXAMPLE
PS> Find-UpdatableModuleHelp "PowerShellGet" -UICulture ja-JP, en-US

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

If the result of Find-UpdatableModuleHelp is null you need to run Update-Help for to download
help info files of installed modules and then try again.

TODO: test UICulture from pipeline
TODO: Not using ValueFromPipeline because an array isn't distinguished from hashtable to select
proper parameter set name
TODO: Before running this function Update-Help must be run as Administrator once on target system to
download required helpinfo.xml files
#>
function Find-UpdatableModuleHelp
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Name")]
	[OutputType([PSModuleInfo])]
	param (
		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = "Name", Position = 0)]
		[SupportsWildcards()]
		[string[]] $Name = "*",

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = "Full", Position = 0,
			HelpMessage = "Specify module to check in the form of ModuleSpecification object")]
		[Microsoft.PowerShell.Commands.ModuleSpecification[]] $FullyQualifiedName,

		[Parameter()]
		[ValidatePattern("^[a-z]{2}-[A-Z]{2}$")]
		[System.Globalization.CultureInfo[]] $UICulture = $DefaultUICulture
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		# https://docs.microsoft.com/en-us/powershell/scripting/developer/help/helpinfo-xml-schema
		$HelpInfoNamespace = @{ helpInfo = 'http://schemas.microsoft.com/powershell/help/2010/05' }

		[PSModuleInfo[]] $Module = @()
	}
	process
	{
		if ($PSCmdlet.ParameterSetName -eq "Name")
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Get-Module -Name '$Name'"
			$Module = Get-Module -ListAvailable -Name $Name | Where-Object -Property HelpInfoUri
		}
		elseif ($PSCmdlet.ParameterSetName -eq "Full")
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Get-Module -FullyQualifiedName '$FullyQualifiedName'"
			$Module = Get-Module -ListAvailable -FullyQualifiedName $FullyQualifiedName | Where-Object -Property HelpInfoUri
		}
		else
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Get-Module -ListAvailable"
			$Module = Get-Module -ListAvailable | Where-Object -Property HelpInfoUri
		}

		if (!$Module)
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] No candidate modules found, aborting"
		}

		foreach ($TargetModule in $Module)
		{
			# Each module has separate xml help info files for each culture
			$InfoXMLFiles = "$($TargetModule.ModuleBase)\*"

			if (Test-Path -PathType Leaf $InfoXMLFiles)
			{
				$Nodes = Get-ChildItem -Path $InfoXMLFiles -Filter *helpinfo.xml -ErrorAction SilentlyContinue |
				Select-Xml -Namespace $HelpInfoNamespace -XPath "//helpInfo:UICulture"

				if ($UICulture)
				{
					# Select only specified cultures
					foreach ($NodeInfo in $Nodes)
					{
						$CultureName = $NodeInfo.Node.UICultureName
						Write-Debug -Message "[$($MyInvocation.InvocationName)] Found culture $CultureName for module '$($TargetModule.Name)'"

						if ($UICulture -contains $CultureName)
						{
							Add-Member -Type NoteProperty -InputObject $TargetModule -Name Culture -Value $NodeInfo.Node.UICultureName
							Add-Member -Type NoteProperty -InputObject $TargetModule -Name CultureVersion -Value $NodeInfo.Node.UICultureVersion -PassThru
						}
					}
				}
				else
				{
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Selecting all cultures for module '$($TargetModule.Name)'"

					# Select all cultures
					foreach ($NodeInfo in $Nodes)
					{
						Add-Member -Type NoteProperty -InputObject $TargetModule -Name Culture -Value $NodeInfo.Node.UICultureName
						Add-Member -Type NoteProperty -InputObject $TargetModule -Name CultureVersion -Value $NodeInfo.Node.UICultureVersion -PassThru
					}
				}
			}
		}
	}
}
