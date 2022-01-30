
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

<#PSScriptInfo

.VERSION 0.12.0

.GUID d1607417-03c5-4295-9b8d-a0b64fb06e7a

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Generate or update help files for all modules in repository

.DESCRIPTION
Update-HelpContent.ps1 Updates existing or generates new help files for all modules
that are part of "Windows Firewall Ruleset" repository.
These Help files are used for online help (Get-Help -Online) and updatable help (Update-Help)

.PARAMETER Module
Specify module name for which to generate help files.
The default is all repository modules

.PARAMETER UICulture
Supported UI cultures for which to generate help files, the default is en-US

.PARAMETER Encoding
Specify encoding for help files.
The default is set by global variable, UTF8 no BOM for Core or UTF8 with BOM for Desktop edition

.PARAMETER Force
If specified, no prompt for confirmation is shown to perform actions, in addition help files
are all removed and regenerated a new instead of being updated.

.EXAMPLE
PS> .\Update-HelpContent.ps1

.EXAMPLE
PS> .\Update-HelpContent.ps1 -Module Ruleset.ProgramInfo

.EXAMPLE
PS> .\Update-HelpContent.ps1 -UICulture @(en-US, fr-FR, jp-JP) -Encoding utf8

.INPUTS
None. You cannot pipe objects to Update-HelpContent.ps1

.OUTPUTS
None. Update-HelpContent.ps1 does not generate any output

.NOTES
See CONTRIBUTING.md in "documentation" section for examples of comment based help that will
produce errors while generating online help and how to avoid them.
Help version is automatically updated according to $ProjectVersion variable.
For best results run first time with -Force switch and second time without -Force switch.
Recommended to generate help files with Core edition because of file encoding.
TODO: some markdown files will end up with additional blank line at the end of document for each
update of help files.
TODO: Online hosting of help content is needed, for now the only purpose is to generate markdown
help files
TODO: about_ topic needs to be manually edited, currently we get template only
To document private functions they must be exported first
TODO: the "Module Name:" entry in help files (any maybe even "external help file:" entry),
if not set to correct module name the command will fail
TODO: Log header is not inserted into logs
TODO: OutputType attribute
TODO: Get rid of blinking progress bar and make your own

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts

.LINK
https://github.com/PowerShell/platyPS
#>

#Requires -Version 5.1

[CmdletBinding(PositionalBinding = $false)]
param (
	[Parameter(Position = 0)]
	[Alias("ModuleName")]
	[string[]] $Module,

	[Parameter()]
	[string[]] $UICulture = @("en-US"),

	[Parameter()]
	$Encoding = $null,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
Initialize-Project -Strict

if ($null -eq $Encoding)
{
	$Encoding = $DefaultEncoding
}

# TODO: Logging solution needed for cases before project initialization
if (!$Develop)
{
	# Run this script only to generate new or update existing online help before release
	Write-Error -Category NotEnabled -TargetObject $Develop `
		-Message "This script is enabled only in development mode"
	return
}

[PSModuleInfo[]] $PlatyModule = Get-Module -Name platyPS -ListAvailable
if ($null -eq $PlatyModule)
{
	Write-Error -Category ObjectNotFound -Message "Module platyPS needs to be installed to run this script"
	return
}

# User prompt
$Deny = "Abort operation, no change to help files is made"
if ($Module)
{
	$Accept = "Generate new or update existing help files for requested modules"
}
else
{
	$Accept = "Generate new or update existing help files for all project modules"
}

if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

<#
.SYNOPSIS
Formatting according to recommended markdown style

.PARAMETER FileName
Markdown file
#>
function Format-Document
{
	[CmdletBinding()]
	[OutputType([void])]
	param (
		[Parameter()]
		[string] $FileName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	$MarkdownFile = Split-Path -Path $FileName -Leaf
	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Formatting document $MarkdownFile"
	$FileData = Get-Content -Path $FileName -Encoding $Encoding -Raw

	# Blank line after heading
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting blank lines around headings in $MarkdownFile"
	$FileData = $FileData -replace '(?m)(?<heading>^#+\s.+$\n)(?=\S)', "`${heading}`r`n"

	# Empty code fences
	# NOTE: module page has no code fences
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting explicit code fences in $MarkdownFile"
	$FileData = $FileData -replace '(?m)(?<fence>^```)(?=\r\n\w+)', "`${fence}powershell"

	# TODO: new line is inserted in module page, NoNewline ignored
	Set-Content -NoNewline -Path $FileName -Value $FileData -Encoding $Encoding
}

# Setup local variables
# Root directory of help content for current module and culture
[string] $HelpContent = "$ProjectRoot\Config\HelpContent\$ProjectVersion"

if (!$Module)
{
	# Generate new or update existing help files for all modules that are part of repository
	$Module = Get-ChildItem -Path $ProjectRoot\Modules\* -Directory -Filter "Ruleset.*" |
	Select-Object -ExpandProperty Name
}

[string] $UpgradeLogsDir = "$ProjectRoot\Logs\HelpContent"

# NOTE: separate folder for upgrade logs
if (!(Test-Path -PathType Container -Path $UpgradeLogsDir))
{
	New-Item -ItemType Container -Path $UpgradeLogsDir | Out-Null
}

foreach ($ModuleName in $Module)
{
	Write-Debug -Message "[$ThisScript] Processing module: $ModuleName"

	# NOTE: Module must be imported to avoid warnings from platyPS
	Import-Module -Name $ModuleName
	[PSModuleInfo] $ModuleInfo = Get-Module -Name $ModuleName

	# Root directory of current module
	[string] $ModuleRoot = $ModuleInfo.ModuleBase

	# Populate help directory and readme if not present
	if (!(Test-Path -Path $ModuleRoot\Help))
	{
		New-Item -Path $ModuleRoot\Help -ItemType Container | Out-Null
	}

	$Readme = "$ModuleRoot\Help\README.md"
	if (!(Test-Path -Path $Readme))
	{
		New-Item -Path $Readme -ItemType File | Out-Null
		Set-Content -Path $Readme -Encoding $Encoding -Value @"

# Help directory

Contains online help files in markdown format.\
These files are used for online reading ex. with `Get-Help -Online`

**NOTE:** The procedure to generate help files will create local only temporary folders in language
specific subfolders
"@
	}

	foreach ($CultureName in $UICulture)
	{
		Write-Debug -Message "[$ThisScript] Processing culture: $CultureName"

		# Root directory of external help files for current module and culture
		[string] $ExternalHelp = "$ModuleRoot\$CultureName"

		# Root directory of online help files for current module and culture
		[string] $OnlineHelp = "$ModuleRoot\Help\$CultureName"

		if ($Force)
		{
			# Remove all online help to regenerate fresh files
			Remove-Item -Path $OnlineHelp -Recurse -ErrorAction Ignore
			Remove-Item -Path $ExternalHelp\*.xml -ErrorAction Ignore
		}

		# Help content download link for Update-Help commandlet
		# This value is required for .cab file creation.
		# This value is used as markdown header metadata in the module page
		[string] $DownloadLink = "https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Config/HelpContent/$ProjectVersion"

		# Module page file
		[string] $ModulePage = "$OnlineHelp\$ModuleName.md"

		# Both the help root folder and module page must exist to update
		if (Test-Path -Path $ModulePage -PathType Leaf)
		{
			Write-Verbose -Message "[$ThisScript] Updating help: $ModuleName - $CultureName"

			# If download link is out of date replace it
			$FileData = Get-Content -Path $ModulePage -Encoding $Encoding

			if ([string]::IsNullOrEmpty($FileData -match "^Download Help Link: $DownloadLink$"))
			{
				Write-Information -Tags $ThisScript -MessageData "INFO: Updating download link in $ModuleName.md"
				$FileData -replace "(?<=Download Help Link:).*", " $DownloadLink" |
				Set-Content -Path $ModulePage -Encoding $Encoding
			}

			# Updates existing help markdown files and creates markdown files for new cmdlets in a module
			# NOTE: updates module page but not about_ topics
			# NOTE: Generates blank module page if missing
			# -Path string[] The folder must contain a module page from which this cmdlet can get the module name
			Update-MarkdownHelpModule -Encoding $Encoding -Path $OnlineHelp -UpdateInputOutput `
				-LogPath $UpgradeLogsDir\$ModuleName-HelpContent.log -UseFullTypeName `
				-RefreshModulePage -Force -ModulePagePath $ModulePage |
			Select-Object -ExpandProperty Name

			# If help version is out of date or missing set it
			$FileData = Get-Content -Path $ModulePage -Encoding $Encoding

			if ([string]::IsNullOrEmpty($FileData -match "Help Version:\s$ProjectVersion"))
			{
				Write-Information -Tags $ThisScript -MessageData "INFO: Updating module page version"
				$FileData = $FileData -replace "(?<=Help Version:).*", " $ProjectVersion"
				Set-Content -Path $ModulePage -Value $FileData -Encoding $Encoding
			}
		}
		else # Generate new help files
		{
			Write-Verbose -Message "[$ThisScript] Generating new help: $ModuleName - $CultureName"

			# NOTE: Need to run to generate module page
			# Regenerates all help files, new ones will be later updated to include "online version" metadata
			# Create new markdown help files (module page included, about module not included)
			New-MarkdownHelp -Module $ModuleName -Encoding $Encoding -OutputFolder $OnlineHelp `
				-UseFullTypeName -WithModulePage -HelpVersion $ProjectVersion -Locale $CultureName `
				-FwLink $DownloadLink -ModulePagePath $ModulePage -Force |
			Select-Object -ExpandProperty Name
			# -Metadata $HelpMetadata
		}

		# NOTE: Need to run to add "online version" metadata to newly generated files which are missing the link
		# Also to perform formatting according to recommended markdown style
		$ModuleFunctions = ($ModuleInfo | Select-Object -ExpandProperty ExportedFunctions).GetEnumerator() |
		Select-Object -ExpandProperty Key

		foreach ($Command in $ModuleFunctions)
		{
			Write-Information -Tags $ThisScript -MessageData "INFO: Formatting document $Command.md"

			# Read file and single line string preserving line break characters
			$FileData = Get-Content -Path $OnlineHelp\$Command.md -Encoding $Encoding -Raw
			$OnlineVersion = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/$ModuleName/Help/$CultureName/$Command.md"

			# If online help link is out of date or missing set it
			if (!($FileData -match "online version:\s$OnlineVersion"))
			{
				Write-Verbose -Message "[$ThisScript] Updating online help link in $Command.md"
				$FileData = $FileData -replace "(?<=online version:).*", " $OnlineVersion"
			}

			# NOTE: NoNewline needed, otherwise each file ends up with 2 final new lines
			Set-Content -NoNewline -Path $OnlineHelp\$Command.md -Value $FileData -Encoding $Encoding

			Format-Document $OnlineHelp\$Command.md
		}

		# Format module page
		Format-Document $ModulePage

		# NOTE: Creating about_ topics is independent of both the Update and New-MarkdownHelp
		if (Test-Path -Path $OnlineHelp\about_$ModuleName.md -PathType Leaf)
		{
			Write-Verbose -Message "[$ThisScript] about_$ModuleName.md is present, no change to file"
		}
		else
		{
			Write-Verbose -Message "[$ThisScript] Generating new about_$ModuleName.md"

			# New about_ModuleName help topic
			New-MarkdownAboutHelp -OutputFolder $OnlineHelp -AboutName $ModuleName
		}

		# Format about topic
		Format-Document $OnlineHelp\about_$ModuleName.md

		Write-Verbose -Message "[$ThisScript] Generating external help"

		# Create new XML help file and *.txt about file or override existing ones
		# TODO: maybe global variable for line width, MaxAboutWidth affects only about_ files
		# NOTE: Creates external help based on files or folders specified in -Path string[]
		New-ExternalHelp -Path $OnlineHelp -Encoding $Encoding -OutputPath $OnlineHelp\External `
			-MaxAboutWidth 120 -ErrorLogFile $UpgradeLogsDir\$ModuleName-ExternalHelp.log -Force |
		Select-Object -ExpandProperty Name
		# -ShowProgress

		Write-Verbose -Message "[$ThisScript] Generating help content"

		# Generate updatable help content
		# NOTE: Requires the path to module page which contains required metadata to name cab file
		# NOTE: Recommend to provide as content only about_ topics and the output from the New-ExternalHelp
		# TODO: resulting helpinfo xml is UTF8 with BOM
		New-ExternalHelpCab -CabFilesFolder $OnlineHelp\External -OutputFolder $OnlineHelp\Content `
			-LandingPagePath $ModulePage | Out-Null
		# -IncrementHelpVersion

		# TODO: maybe moving files instead of copying
		Write-Information -Tags $ThisScript -MessageData "INFO: Copying generated help files to default location"

		# Copy HelpInfo file to default destination
		Copy-Item -Path $OnlineHelp\Content\* -Filter *.xml -Destination $ModuleRoot

		# Copy required help content to default destination
		if (!(Test-Path -Path $HelpContent -PathType Container))
		{
			New-Item -Path $HelpContent -ItemType Container | Out-Null
		}

		Copy-Item -Path $OnlineHelp\Content\* -Filter *.cab -Destination $HelpContent

		# Copy required external help to default destination
		if (!(Test-Path -Path $ExternalHelp -PathType Container))
		{
			New-Item -Path $ExternalHelp -ItemType Container | Out-Null
		}

		# TODO: We're skipping copying about_ topic file to prevent overwriting original with template
		Copy-Item -Path $OnlineHelp\External\* -Filter *.xml -Destination $ExternalHelp

		Update-Log
	} # foreach culture

	Update-Log
} # foreach module

Update-Log
