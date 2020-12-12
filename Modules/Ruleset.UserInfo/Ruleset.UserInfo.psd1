
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

#
# Module manifest for module "Ruleset.UserInfo"
#
# Generated by: metablaster
#
# Generated on: 11.2.2020.
#

@{
	# Script module or binary module file associated with this manifest.
	RootModule = "Ruleset.UserInfo.psm1"

	# Version number of this module.
	ModuleVersion = "0.8.1"

	# Supported PSEditions
	CompatiblePSEditions = @(
		"Core"
		"Desktop"
	)

	# ID used to uniquely identify this module
	GUID = "136254f4-4730-4ed1-b9e9-1ccecfe09ee9"

	# Author of this module
	Author = "metablaster zebal@protonmail.ch"

	# Company or vendor of this module
	# CompanyName = "Unknown"

	# Copyright statement for this module
	Copyright = "Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch"

	# Description of the functionality provided by this module
	Description = "Module to query user and group information for 'Windows Firewall Ruleset' project"

	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = "5.1"

	# Name of the Windows PowerShell host required by this module
	# PowerShellHostName = ""

	# Minimum version of the Windows PowerShell host required by this module
	# PowerShellHostVersion = ""

	# Minimum version of Microsoft .NET Framework required by this module.
	# This prerequisite is valid for the PowerShell Desktop edition only.
	DotNetFrameworkVersion = "4.5"

	# Minimum version of the common language runtime (CLR) required by this module.
	# This prerequisite is valid for the PowerShell Desktop edition only.
	CLRVersion = "4.0"

	# Processor architecture (None, X86, Amd64) required by this module
	ProcessorArchitecture = "None"

	# Modules that must be imported into the global environment prior to importing this module
	# RequiredModules = @()

	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = @()

	# Script files (.ps1) that are run in the caller's environment prior to importing this module.
	# ScriptsToProcess = @()

	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @()

	# Format files (.ps1xml) to be loaded when importing this module
	# FormatsToProcess = @()

	# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
	# NestedModules = @()

	# Functions to export from this module, for best performance, do not use wildcards and do not
	# delete the entry, use an empty array if there are no functions to export.
	FunctionsToExport = @(
		"ConvertFrom-SID"
		"ConvertFrom-UserAccount"
		"Get-AccountSID"
		"Get-GroupPrincipal"
		"Get-GroupSID"
		"Get-SDDL"
		"Get-UserGroup"
		"Merge-SDDL"
	)

	# Cmdlets to export from this module, for best performance, do not use wildcards and do not
	# delete the entry, use an empty array if there are no cmdlets to export.
	CmdletsToExport = @()

	# Variables to export from this module
	VariablesToExport = @(
		"CheckInitUserInfo"
		"UsersGroupSDDL"
		"AdministratorsGroupSDDL"
		"NT_AUTHORITY_System"
		"NT_AUTHORITY_LocalService"
		"NT_AUTHORITY_NetworkService"
		"NT_AUTHORITY_UserModeDrivers"
	)

	# Aliases to export from this module, for best performance, do not use wildcards and do not
	# delete the entry, use an empty array if there are no aliases to export.
	AliasesToExport = @()

	# DSC resources to export from this module
	# DscResourcesToExport = @()

	# List of all modules packaged with this module
	# ModuleList = @()

	# List of all files packaged with this module
	FileList = @(
		"en-US\about_Ruleset.UserInfo.help.txt"
		"en-US\Ruleset.UserInfo-help.xml"
		"Help\en-US\about_Ruleset.UserInfo.md"
		"Help\en-US\ConvertFrom-SID.md"
		"Help\en-US\ConvertFrom-UserAccount.md"
		"Help\en-US\Get-AccountSID.md"
		"Help\en-US\Get-GroupPrincipal.md"
		"Help\en-US\Get-GroupSID.md"
		"Help\en-US\Get-SDDL.md"
		"Help\en-US\Get-UserGroup.md"
		"Help\en-US\Merge-SDDL.md"
		"Help\en-US\Ruleset.UserInfo.md"
		"Help\README.md"
		"Public\ConvertFrom-SID.ps1"
		"Public\ConvertFrom-UserAccount.ps1"
		"Public\Get-AccountSID.ps1"
		"Public\Get-GroupPrincipal.ps1"
		"Public\Get-GroupSID.ps1"
		"Public\Get-SDDL.ps1"
		"Public\Get-UserGroup.ps1"
		"Public\Merge-SDDL.ps1"
		"Public\README.md"
		"Ruleset.UserInfo_136254f4-4730-4ed1-b9e9-1ccecfe09ee9_HelpInfo.xml"
		"Ruleset.UserInfo.psd1"
		"Ruleset.UserInfo.psm1"
	)

	# Private data to pass to the module specified in RootModule/ModuleToProcess.
	# This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{

		PSData = @{

			# Tags applied to this module. These help with module discovery in online galleries.
			Tags = @(
				"UserInfo"
				"ComputerUsers"
				"Users"
			)

			# A URL to the license for this module.
			LicenseUri = "https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/master/LICENSE"

			# A URL to the main website for this project.
			ProjectUri = "https://github.com/metablaster/WindowsFirewallRuleset"

			# A URL to an icon representing this module.
			# IconUri = ""

			# ReleaseNotes of this module
			# ReleaseNotes = ""

			# Prerelease string of this module
			Prerelease = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Readme/CHANGELOG.md"

			# Flag to indicate whether the module requires explicit user acceptance for install, update, or save.
			RequireLicenseAcceptance = $true

			# A list of external modules that this module is dependent upon.
			# ExternalModuleDependencies = @()
		} # End of PSData hashtable
	} # End of PrivateData hashtable

	# HelpInfo URI of this module
	# HelpInfoURI = "https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/master/Modules/Ruleset.UserInfo/Ruleset.UserInfo_136254f4-4730-4ed1-b9e9-1ccecfe09ee9_HelpInfo.xml"

	# Default prefix for commands exported from this module.
	# Override the default prefix using Import-Module -Prefix.
	# DefaultCommandPrefix = ""
}
