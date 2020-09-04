
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
.PARAMETER SupportedUICulture
Supported UI cultures for which to generate help, the default is en-US
.EXAMPLE
UpdateHelp.ps1
.INPUTS
None. You cannot pipe objects to UpdateHelp.ps1
.OUTPUTS
None. UpdateHelp.ps1 does not generate any output
.NOTES
None.
#>

param (
	[switch] $PerModule,
	[string[]] $SupportedUICulture = @(
		"en-US"
	)
)

# Initialization
. $PSScriptRoot\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# User prompt
$Accept = "Generate or update help files for all project modules"
$Deny = "Skip operation, no change to project modules help files is made"
Update-Context $ScriptContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

# Setup local variables
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

$UTF8 = New-Object System.Text.UTF8Encoding -ArgumentList $false

foreach ($ModuleName in $TargetModules)
{
	foreach ($UICulture in $SupportedUICulture)
	{
		Import-Module -Name $ModuleName
		[PSModuleInfo] $ModuleInfo = Get-Module -Name $ModuleName

		[string] $HelpPath = "$($ModuleInfo.ModuleBase)\Help"
		# [string] $GUID = $ModuleInfo | Select-Object -ExpandProperty GUID

		# Generate help based on module
		if ($PerModule)
		{
			[string] $DownloadLink = "https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/develop/Modules/$ModuleName/Help/Content"

			if (Test-Path -Path $HelpPath -PathType Container)
			{
				# NOTE: not needed, Update-MarkdownHelpModule does better job
				# Update-MarkdownHelp -Encoding $UTF8 -Path $HelpPath -UpdateInputOutput -Force `
				# 	-LogPath $ProjectRoot\Logs\$ModuleName-Help.log -UseFullTypeName

				# Update existing markdown help files and about_ModuleName topic, add new ones as needed
				Update-MarkdownHelpModule -Encoding $UTF8 -Path $HelpPath -UpdateInputOutput -Force `
					-LogPath $ProjectRoot\Logs\$ModuleName-UpdateHelp.log -UseFullTypeName `
					-RefreshModulePage
			}
			else
			{
				# NOTE: Item has already been added
				# "Module Name" = $ModuleName
				# "external help file" = "$ModuleName.psm1-help.xml"
				# "online version" = $DownloadLink

				# [hashtable] $HelpMetadata = @{
				# 	"Module Guid" = $GUID
				# 	"Download Help Link" = "$DownloadLink"
				# 	"Help Version" = $ProjectVersion
				# 	Locale = $UICulture
				# }

				# Create new markdown help files
				New-MarkdownHelp @Logs -Module $ModuleName -Encoding $UTF8 -OutputFolder $HelpPath -Force `
					-UseFullTypeName -WithModulePage -HelpVersion $ProjectVersion -Locale $UICulture `
					-FwLink $DownloadLink -ConvertNotesToList # -Metadata $HelpMetadata
				# -NoMetadata -ModulePagePath

				# New about_ModuleName help topic
				New-MarkdownAboutHelp -OutputFolder $HelpPath -AboutName $ModuleName @Logs
			}
		}
		else
		{
			# Generate help per file
			$ModuleCommands = ($ModuleInfo | Select-Object -ExpandProperty ExportedCommands).GetEnumerator() | Select-Object -ExpandProperty Key

			foreach ($Command in $ModuleCommands)
			{
				[string] $OnlineVersion = "https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/develop/Modules/$ModuleName/Help/$Command.md"

				if (Test-Path -Path $HelpPath\$Command -PathType Leaf)
				{
					# NOTE: since individual file is tested we don't update entry directory
					Update-MarkdownHelp -Encoding $UTF8 -Path $HelpPath -UpdateInputOutput -Force `
						-LogPath $ProjectRoot\Logs\$ModuleName-UpdateHelp.log -UseFullTypeName

					# Update existing markdown help files and about_ModuleName topic, add new ones as needed
					# Update-MarkdownHelpModule -Encoding $UTF8 -Path $HelpPath -UpdateInputOutput -Force `
					# 	-LogPath $ProjectRoot\Logs\$ModuleName-UpdateHelp.log -UseFullTypeName `
					# 	-RefreshModulePage
				}
				else
				{
					# NOTE: Item has already been added
					# "Module Name" = $ModuleName
					# "external help file" = "$ModuleName.psm1-help.xml"
					# "online version" = $DownloadLink

					# [hashtable] $HelpMetadata = @{
					# 	"Module Guid" = $GUID
					# 	"Download Help Link" = "$DownloadLink"
					# 	"Help Version" = $ProjectVersion
					# 	Locale = $UICulture
					# }

					# Create new markdown help files
					New-MarkdownHelp -Command $Command -Encoding $UTF8 -OutputFolder $HelpPath -Force `
						-UseFullTypeName -OnlineVersionUrl $OnlineVersion @Logs
					# -NoMetadata -ModulePagePath -Metadata $HelpMetadata
					# -Locale $UICulture -FwLink $DownloadLink -HelpVersion $ProjectVersion
				}
			}

			# NOTE: Updating or creating needed only one
			# New about_ModuleName help topic
			New-MarkdownAboutHelp -OutputFolder $HelpPath -AboutName $ModuleName @Logs
		}

		# Create new XML help file and *.txt about file or override existing ones
		New-ExternalHelp -Path $HelpPath -Encoding $UTF8 -OutputPath $HelpPath\$UICulture -Force `
			-MaxAboutWidth 120 -ErrorLogFile $ProjectRoot\Logs\$ModuleName-ExternalHelpError.log `
			-ShowProgress

		# NOTE: not needed, previous markdown output is good enough
		# Create module markdown help files that contains all the metadata required to output the .cab file
		# New-MarkdownHelp -ModuleName $ModuleName -MamlFile $HelpPath\$UICulture\$ModuleName-help.xml `
		# 	-Encoding $UTF8 -OutputFolder $HelpPath\Metadata -UseFullTypeName -WithModulePage `
		# 	-ModuleGuid $GUID -HelpVersion $ProjectVersion -Locale $UICulture -FwLink $DownloadLink

		# Generate CAB files
		New-ExternalHelpCab -CabFilesFolder $HelpPath\$UICulture @Logs `
			-OutputFolder $HelpPath\Content -LandingPagePath $HelpPath\$ModuleName.md
		# -IncrementHelpVersion
	}
}

Update-Log
