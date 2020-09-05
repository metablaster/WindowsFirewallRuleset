
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
UpdateHelp.ps1 SupportedUICulture @(en-US, fr-FR, jp-JP)
.INPUTS
None. You cannot pipe objects to UpdateHelp.ps1
.OUTPUTS
None. UpdateHelp.ps1 does not generate any output
.NOTES
See CONTRIBUTING.md in "documentation" section for examples of comment based help that will
produce errors while generating online help and how to avoid them
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
# Specifies the character encoding for markdown help files
$UTF8 = New-Object System.Text.UTF8Encoding -ArgumentList $false @Logs

# Root directory of help content for current module and culture
[string] $HelpContent = "$ProjectRoot\Config\HelpContent\$ProjectVersion"

# Generate new or update existing help files for all modules that are part of repository
$TargetModules = Get-ChildItem -Path $ProjectRoot\Modules -Directory |
Where-Object -Property Name -Like "Project.*" |
Select-Object -Property Name

# Counters for progress
[int32] $ProgressCount = 0

foreach ($ModuleDirectory in $TargetModules)
{
	[string] $ModuleName = $ModuleDirectory.Name
	Write-Debug -Message "[$ThisScript] Processing module: $ModuleName"

	# NOTE: Module must be imported to avoid warnings from platyPS
	Import-Module -Name $ModuleName
	[PSModuleInfo] $ModuleInfo = Get-Module -Name $ModuleName @Logs

	# Root directory of current module
	[string] $ModuleRoot = $ModuleInfo.ModuleBase

	# Populate help directory and readme if not present
	if (!(Test-Path -Path $ModuleRoot\Help))
	{
		New-Item -Path $ModuleRoot\Help -ItemType Container @Logs | Out-Null
	}

	$Readme = "$ModuleRoot\Help\README.md"
	if (!(Test-Path -Path $Readme))
	{
		New-Item -Path $Readme -ItemType File @Logs | Out-Null
		Set-Content -Path $Readme -Encoding utf8 -Value @"

# Help directory

Contains online help files

While generating help files, temporary folders may appear in language specific subfolders
"@
	}

	foreach ($UICulture in $SupportedUICulture)
	{
		Write-Progress -Activity "Creating help files" -CurrentOperation $ModuleName -Status $UICulture `
			-PercentComplete (++$ProgressCount / $TargetModules.Length * $SupportedUICulture.Length * 100)

		Write-Debug -Message "[$ThisScript] Processing culture: $UICulture"

		# Root directory of external help files for current module and culture
		[string] $ExternalHelp = "$ModuleRoot\$UICulture"

		# Root directory of online help files for current module and culture
		[string] $OnlineHelp = "$ModuleRoot\Help\$UICulture"

		# Help content download link for Update-Help commandlet
		# This value is required for .cab file creation. This value is used as markdown header metadata in the module page
		[string] $DownloadLink = "https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/develop/Config/Content/$ProjectVersion"

		# Module page file
		[string] $ModulePage = "$OnlineHelp\$ModuleName.md"

		# If module page exists, perform update
		[bool] $Update = Test-Path -Path $ModulePage -PathType Leaf

		# Both the help root folder and module page must exist to update
		# NOTE: The folder must contain a module page from which this cmdlet can get the module name
		if ($Update)
		{
			Write-Verbose -Message "[$ThisScript] Updating help: $ModuleName - $UICulture"

			# If download link is out of date replace it
			$FileData = Get-Content $ModulePage
			if (!($FileData -match "^Download Help Link: $DownloadLink$").Length)
			{
				Write-Information -Tags "Project" -MessageData "INFO: Updating download link in $ModuleName.md"
				$FileData -replace "(?<=Download Help Link: ).+", $DownloadLink |
				Set-Content -Path $ModulePage -Encoding utf8
			}

			# Updates existing help markdown files and creates markdown files for new cmdlets in a module
			# NOTE: updates module page but not about_ topics
			# NOTE: Generates blank module page if missing
			# NOTE: We can't use Metadata parameter here to enter "online version:" link
			# -Path string[] The folder must contain a module page from which this cmdlet can get the module name
			Update-MarkdownHelpModule -Encoding $UTF8 -Path $OnlineHelp -UpdateInputOutput `
				-LogPath $ProjectRoot\Logs\$ModuleName-UpdateHelp.log -UseFullTypeName `
				-RefreshModulePage -Force -ModulePagePath $ModulePage |
			Select-Object -ExpandProperty Name
		}
		else # Generate new help files
		{
			Write-Verbose -Message "[$ThisScript] Generating new help: $ModuleName - $UICulture"

			# NOTE: Need to run to generate module page
			# Regenerates all help files, new ones will be later updated to include "online version" metadata
			# Create new markdown help files (module page included, about module not included)
			New-MarkdownHelp -Module $ModuleName -Encoding $UTF8 -OutputFolder $OnlineHelp `
				-UseFullTypeName -WithModulePage -HelpVersion $ProjectVersion -Locale $UICulture `
				-FwLink $DownloadLink -ModulePagePath $ModulePage -Force @Logs |
			Select-Object -ExpandProperty Name
			# -Metadata $HelpMetadata
		}

		# NOTE: Need to run to add "online version" metadata to newly generated files which are missing the link
		$ModuleCommands = ($ModuleInfo | Select-Object -ExpandProperty ExportedCommands).GetEnumerator() |
		Select-Object -ExpandProperty Key

		foreach ($Command in $ModuleCommands)
		{
			Write-Debug -Message "[$ThisScript] Processing command: $Command"

			# If online help link is out of date or missing set it
			$FileData = Get-Content $OnlineHelp\$Command.md
			[string] $OnlineVersion = "https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/$ModuleName/Help/$UICulture/$Command.md"

			if (!($FileData -match "^online version:\s$OnlineVersion$").Length)
			{
				Write-Information -Tags "Project" -MessageData "INFO: Updating online help link in $Command.md"
				$FileData -replace "(?<=online version:).*", " $OnlineVersion" |
				Set-Content -Path $OnlineHelp\$Command.md -Encoding utf8
			}
		}

		# NOTE: Creating about_ topics is independent of both the Update and New-MarkdownHelp
		if (Test-Path -Path $OnlineHelp\about_$ModuleName.md -PathType Leaf)
		{
			Write-Verbose -Message "[$ThisScript] about_$ModuleName.md is present, no change to file"
		}
		else
		{
			Write-Verbose -Message "[$ThisScript] Generating new about_$ModuleName.md"

			# New about_ModuleName help topic
			New-MarkdownAboutHelp -OutputFolder $OnlineHelp -AboutName $ModuleName @Logs
		}

		Write-Verbose -Message "[$ThisScript] Generating external help"

		# Create new XML help file and *.txt about file or override existing ones
		# TODO: maybe global variable for line width, MaxAboutWidth affects only about_ files
		# NOTE: Creates external help based on files or folders specified in -Path string[]
		New-ExternalHelp -Path $OnlineHelp -Encoding $UTF8 -OutputPath $OnlineHelp\External -Force `
			-MaxAboutWidth 120 -ErrorLogFile $ProjectRoot\Logs\$ModuleName-ExternalHelp.log |
		Select-Object -ExpandProperty Name
		# -ShowProgress

		Write-Verbose -Message "[$ThisScript] Generating help content"

		# Generate updatable help content
		# NOTE: Requires the path to module page which contains required metadata to name cab file
		# NOTE: Recommend to provide as content only about_ topics and the output from the New-ExternalHelp
		New-ExternalHelpCab -CabFilesFolder $OnlineHelp\External -OutputFolder $OnlineHelp\Content `
			-LandingPagePath $ModulePage @Logs | Out-Null
		# -IncrementHelpVersion

		# TODO: maybe moving files instead of copying
		Write-Information -Tags "Project" -MessageData "INFO: Copying generated help files to default location"

		# Copy HelpInfo file to default destination
		Copy-Item -Path $OnlineHelp\Content\* -Filter *.xml -Destination $ModuleRoot @Logs

		# Copy required help content to default destination
		if (!(Test-Path -Path $HelpContent -PathType Container @Logs))
		{
			New-Item -Path $HelpContent -ItemType Container @Logs | Out-Null
		}

		Copy-Item -Path $OnlineHelp\Content\* -Filter *.cab -Destination $HelpContent @Logs

		# Copy required external help to default destination
		if (!(Test-Path -Path $ExternalHelp -PathType Container @Logs))
		{
			New-Item -Path $ExternalHelp -ItemType Container @Logs | Out-Null
		}

		Copy-Item -Path $OnlineHelp\External\* -Filter *.xml -Destination $ExternalHelp @Logs

		Update-Log
	} # foreach culture

	Update-Log
} # foreach module

Update-Log
