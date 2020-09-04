
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
Generate or update help files for all project modules
.DESCRIPTION
UpdateHelp.ps1 Updates existing or generates new help files for all modules
that are part of "Windows Firewall Ruleset" repository
These Help files are used for online help (Get-Help -Online) and
updatable help for (Update-Help)
.PARAMETER SupportedUICulture
Supported UI cultures for which to generate help files, the default is en-US
.PARAMETER IncrementVersion
If specified, increments help version to match $ProjectVersion variable
TODO: not implemented
.EXAMPLE
UpdateHelp.ps1
.EXAMPLE
UpdateHelp.ps1 -IncrementVersion
.EXAMPLE
UpdateHelp.ps1 -PerModule SupportedUICulture @(en-US, fr-FR, jp-JP)
.INPUTS
None. You cannot pipe objects to UpdateHelp.ps1
.OUTPUTS
None. UpdateHelp.ps1 does not generate any output
.NOTES
None.
#>

[CmdletBinding()]
param (
	[string[]] $SupportedUICulture = @(
		"en-US"
	),
	[switch] $IncrementVersion
)

# Initialization
. $PSScriptRoot\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# TODO: Need logging solution for cases before project initialization
if (!$Develop)
{
	# We run this script only to generate new or update existing online help
	Write-Error -Category NotEnabled -TargetObject $Develop `
		-Message "This script is enabled only in development mode"
	return
}

[PSModuleInfo[]] $PlatyModule = Get-Module -Name platyPS -ListAvailable
if ($null -eq $PlatyModule)
{
	Write-Error -Category ObjectNotFound -TargetObject $PlatyModule `
		-Message "Module platyPS needs to be installed to run this script"
	return
}

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# User prompt
$Accept = "Generate new or update existing help files for all project modules"
$Deny = "Abort operation, no change to help files is made"
Update-Context $ScriptContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

Write-Debug -Message "[$ThisScript] params($($PSBoundParameters.Values))"

# Setup local variables
$UTF8 = New-Object System.Text.UTF8Encoding -ArgumentList $false @Logs

# TODO: Process all modules
# $TargetModules = Get-ChildItem -Path $ProjectRoot\Modules -Directory |
# Where-Object -Property Name -Like "Project.*" |
# Select-Object -ExpandProperty Name

$TargetModules = @(
	# "Project.AllPlatforms.Logging"
	"Project.AllPlatforms.Initialize"
	# "Project.AllPlatforms.Test"
	# "Project.AllPlatforms.Utility"
	# "Project.Windows.UserInfo"
	# "Project.Windows.ComputerInfo"
	# "Project.Windows.ProgramInfo"
	# "Project.Windows.Firewall"
)

foreach ($ModuleName in $TargetModules)
{
	Write-Debug -Message "[$ThisScript] Processing module: $ModuleName"

	[PSModuleInfo] $ModuleInfo = Get-Module -Name $ModuleName @Logs

	foreach ($UICulture in $SupportedUICulture)
	{
		Write-Debug -Message "[$ThisScript] Processing culture: $UICulture"

		# Root directory for current module and culture online help
		[string] $HelpPath = "$($ModuleInfo.ModuleBase)\Help\$UICulture"

		# Help content download link
		# TODO: need versioning folder
		[string] $DownloadLink = "https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/develop/Modules/$ModuleName/Help/Content"

		# If help files exist perform update
		[bool] $ModulePage = Test-Path -Path $HelpPath\$ModuleName.md -PathType Leaf

		# Both help root folder and module page must exist to update files
		if ($ModulePage)
		{
			Write-Verbose -Message "[$ThisScript] Updating help: $ModuleName\$UICulture"

			# Update existing markdown help files and add new ones as needed
			# NOTE: updates module page but not about_ModuleName topic
			# NOTE: Generates blank module page if missing
			# NOTE: We can't use Metadata parameter here to enter "online version:" link
			Update-MarkdownHelpModule -Encoding $UTF8 -Path $HelpPath -UpdateInputOutput -Force `
				-LogPath $ProjectRoot\Logs\$ModuleName-UpdateHelp.log -UseFullTypeName `
				-RefreshModulePage | Select-Object -ExpandProperty Name

			# Updates existing only markdown files
			# NOTE: does not update module page nor about_ModuleName topic
			# Update-MarkdownHelp -Encoding $UTF8 -Path $HelpPath -UpdateInputOutput -Force `
			# 	-LogPath $ProjectRoot\Logs\$ModuleName-UpdateHelp.log -UseFullTypeName
		}
		else # Generate new help files
		{
			Write-Verbose -Message "[$ThisScript] Generating new help: $ModuleName\$UICulture"

			# NOTE: Need to run to generate module page
			# generated help files will be overwritten to include "online version" metadata

			# Create new markdown help files (module page included, about module not included)
			New-MarkdownHelp @Logs -Module $ModuleName -Encoding $UTF8 -OutputFolder $HelpPath -Force `
				-UseFullTypeName -WithModulePage -HelpVersion $ProjectVersion -Locale $UICulture `
				-FwLink $DownloadLink | Select-Object -ExpandProperty Name
		} # if/else update help

		# NOTE: Need to run to add "online version" metadata to files that are missing the link
		# Generate help per command
		$ModuleCommands = ($ModuleInfo | Select-Object -ExpandProperty ExportedCommands).GetEnumerator() |
		Select-Object -ExpandProperty Key

		foreach ($Command in $ModuleCommands)
		{
			Write-Debug -Message "[$ThisScript] Processing command: $Command"

			foreach ($Line in Get-Content $HelpPath\$Command.md)
			{
				if ($Line -match "^online version:")
				{
					if ($Line -match "^online version:\s\w+")
					{
						Write-Debug -Message "[$ThisScript] Online version link in $Command.md is present, not regenerating file"
						continue
					}

					Write-Verbose -Message "[$ThisScript] Regenerating file $Command.md to include online version link"
					[string] $OnlineVersion = "https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/develop/Modules/$ModuleName/Help/$Command.md"

					# Create new markdown help files (both module page and about module not included)
					New-MarkdownHelp -Command $Command -Encoding $UTF8 -OutputFolder $HelpPath -Force `
						-UseFullTypeName -OnlineVersionUrl $OnlineVersion @Logs | Select-Object -ExpandProperty Name
					# -NoMetadata -ModulePagePath -Metadata $HelpMetadata
					# -Locale $UICulture -FwLink $DownloadLink -HelpVersion $ProjectVersion
				}
			}
		}

		if (Test-Path -Path $HelpPath\about_$ModuleName.md -PathType Leaf)
		{
			Write-Verbose -Message "[$ThisScript] about_$ModuleName.md is present, no change to file"
		}
		else
		{
			Write-Verbose -Message "[$ThisScript] Generating new about_$ModuleName.md"

			# NOTE: Creating about topics is independent of both the Update and New-MarkdownHelp
			# New about_ModuleName help topic
			New-MarkdownAboutHelp -OutputFolder $HelpPath -AboutName $ModuleName @Logs
		}

		Write-Verbose -Message "[$ThisScript] Generating external help"

		# Create new XML help file and *.txt about file or override existing ones
		# TODO: maybe global variable for line width
		New-ExternalHelp -Path $HelpPath -Encoding $UTF8 -OutputPath $HelpPath\External -Force `
			-MaxAboutWidth 120 -ErrorLogFile $ProjectRoot\Logs\$ModuleName-ExternalHelpError.log `
			-ShowProgress | Select-Object -ExpandProperty Name

		Write-Verbose -Message "[$ThisScript] Generating help content"

		# Generate CAB files
		New-ExternalHelpCab -CabFilesFolder $HelpPath\External @Logs `
			-OutputFolder $HelpPath\Content -LandingPagePath $HelpPath\$ModuleName.md | Out-Null
		# -IncrementHelpVersion

		Update-Log
	} # foreach culture

	Update-Log
} # foreach module

Update-Log
