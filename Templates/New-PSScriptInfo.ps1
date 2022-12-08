
#
# All the metadata properties to create a new script file info
#
# https://docs.microsoft.com/en-us/powershell/module/powershellget/new-scriptfileinfo
#

$Params = @{
	# Specifies the location where the script file is saved
	# TODO: Update script file path
	Path = ".\New-Script.ps1"

	# Specifies a unique ID for the script
	# TODO: Comment out or generate new GUID with [guid]::NewGuid()
	Guid = "66e38822-834d-4a90-b9c6-9e600a472a0a"

	# Specifies the version of the script
	Version = "0.14.0"

	# Specifies the script author
	Author = "metablaster zebal@protonmail.com"

	# Specifies a description for the script
	Description = "New script file"

	# Specifies the company or vendor who created the script
	# CompanyName = ""

	# Specifies a copyright statement for the script
	Copyright = "Copyright (C) 2022 metablaster zebal@protonmail.ch"

	# Specifies an array of external module dependencies
	# ExternalModuleDependencies = @()

	# Specifies an array of required scripts
	# RequiredScripts = @()

	# Specifies an array of external script dependencies
	# ExternalScriptDependencies = @()

	# Specifies an array of tags
	Tags = @("TemplateTag")

	# Specifies the URL of a web page about this project
	ProjectUri = "https://github.com/metablaster/WindowsFirewallRuleset"

	# Specifies the URL of licensing terms
	LicenseUri = "https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/master/LICENSE"

	# Specifies the URL of an icon for the script.
	# The specified icon is displayed on the gallery web page for the script
	# IconUri = ""

	# Specifies a string array that contains release notes or comments that you want available to
	# users of this version of the script
	ReleaseNotes = @(
		"https://github.com/metablaster/WindowsFirewallRuleset/blob/master/docs/CHANGELOG.md"
	)

	# Specifies modules that must be in the global session state.
	# If the required modules aren't in the global session state, PowerShell imports them.
	# RequiredModules = @()

	# Specifies private data for the script
	# PrivateData
}

New-ScriptFileInfo @Params
Test-ScriptFileInfo -Path $Params.Path
