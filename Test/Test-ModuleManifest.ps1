
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
Unit test to test module manifest files

.DESCRIPTION
Verifies that a module manifest files accurately describe the contents of modules in repository,
for binary files also verifies digital signature is valid

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Test-ModuleManifest.ps1

.INPUTS
None. You cannot pipe objects to Test-ModuleManifest.ps1

.OUTPUTS
None. Test-ModuleManifest.ps1 does not generate any output

.NOTES
TODO: ExternalModuleDependencies should be tested, for which we need an algorithm to
gather all the function used in module and to which modules they belong

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Test/README.md
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\ContextSetup.ps1

if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test

if ($PSVersionTable.PSEdition -eq "Desktop")
{
	# NOTE: Ruleset.Compatibility requires PowerShell Core
	# VSSetup is digitally signed and we can't modify missing manifest file entries
	$Manifests = Get-ChildItem -Name -Depth 1 -Recurse -Path "$ProjectRoot\Modules" -Filter "*.psd1" -Exclude "*Ruleset.Compatibility*", VSSetup*
}
else
{
	$Manifests = Get-ChildItem -Name -Depth 1 -Recurse -Path "$ProjectRoot\Modules" -Filter "*.psd1" -Exclude VSSetup*
}

[string[]] $GUID = @()

foreach ($Manifest in $Manifests)
{
	# Perform basic manifest test, which checks only for required elements
	Test-ModuleManifest -Path $ProjectRoot\Modules\$Manifest

	# Get information about the module
	[PSModuleInfo] $Module = Get-Module -ListAvailable -Name $ProjectRoot\Modules\$Manifest
	[string] $ThisGUID = $Module | Select-Object -ExpandProperty GUID
	[string] $HelpInfo = "$($Module.ModuleBase)\$($Module.Name)_$($ThisGUID)_HelpInfo.xml"

	# Check HelpInfo file exists and is properly named
	if (!(Test-Path -Path $HelpInfo))
	{
		Write-Error -Category InvalidResult -TargetObject $HelpInfo `
			-Message "HelpInfo file doesn't exist for module '$($Module.Name)' module"
	}

	# Verify module version is same as repository version
	if ($Module.Version -ne $ProjectVersion)
	{
		Write-Error -Category InvalidResult -TargetObject $HelpInfo `
			-Message "Module version $($Module.Version) doesn't match with project version $ProjectVersion in '$Manifest' manifest"
	}

	# Verify module Copyright exists and is of correct syntax
	if ([string]::IsNullOrEmpty($Module.Copyright) -or
		($Module.Copyright -cnotmatch "Copyright \(C\)\s\d{4}((-|,\s)\d{4})?\s\w+(\s\w+)?|(\w+@\w{3}$)"))
	{
		Write-Error -Category InvalidResult -TargetObject $HelpInfo `
			-Message "Module Copyright entry is not properly formatted or doesn't exist for $Manifest manifest"
	}

	# Verify module manifest is a script module and not binary
	if ($Module.ModuleType -ne "Script")
	{
		Write-Error -Category InvalidResult -TargetObject $HelpInfo `
			-Message "'$($Module.Name)' module is expected to be a script module"
	}

	# Verify module manifest has description
	if ([string]::IsNullOrEmpty($Module.Description))
	{
		Write-Error -Category InvalidResult -TargetObject $HelpInfo `
			-Message "Module description does not exist in '$Manifest' manifest"
	}

	# Verify module manifest has author specified
	if ([string]::IsNullOrEmpty($Module.Author))
	{
		Write-Error -Category InvalidResult -TargetObject $HelpInfo `
			-Message "Module author does not exist in '$Manifest' manifest"
	}

	# Verify PS version
	if (($Module.PowerShellVersion -lt "5.1") -or ($Module.PowerShellVersion -gt $RequirePSVersion))
	{
		Write-Error -Category InvalidResult -TargetObject $HelpInfo `
			-Message "Expected 4.0 'ClrVersion' in '$Manifest' manifest"
	}

	# Verify .NET and CRL is of expected value
	if ($Module.DotNetFrameworkVersion -ne "4.5")
	{
		Write-Error -Category InvalidResult -TargetObject $HelpInfo `
			-Message "Expected 4.5 'DotNetFrameworkVersion' in '$Manifest' manifest"
	}

	if ($Module.ClrVersion -ne "4.0")
	{
		Write-Error -Category InvalidResult -TargetObject $HelpInfo `
			-Message "Expected 4.0 'ClrVersion' in '$Manifest' manifest"
	}

	# Verify links specified in manifest are valid
	foreach ($URL in @($Module.LicenseUri, $Module.IconUri, $Module.ProjectUri))
	{
		if ([string]::IsNullOrEmpty($URL))
		{
			Write-Error -Category InvalidResult -TargetObject $HelpInfo `
				-Message "Either LicenseUri, IconUri or ProjectUri is not specified in '$Manifest' manifest"
		}
		else
		{
			try
			{
				# Suppress progress bar from Invoke-WebRequest
				$DefaultProgress = $ProgressPreference
				$ProgressPreference = "SilentlyContinue"

				# [Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject]
				Invoke-WebRequest -Uri $URL | Out-Null
			}
			catch
			{
				Write-Error -Category InvalidResult -TargetObject $HelpInfo `
					-Message "IconUri or LicenseUri specified is not reachable for '$($Module.Name)' module '$URL'"
			}
			finally
			{
				$ProgressPreference = $DefaultProgress
			}
		}
	}

	$PrivateData = $Module.PrivateData.PSData
	# Verify the module enforces license acceptance
	if ($PrivateData.RequireLicenseAcceptance -ne $true)
	{
		Write-Error -Category InvalidResult -TargetObject $HelpInfo `
			-Message "'$($Module.Name)' module does not enforce license acceptance"
	}

	# Verify either release or prerelease notes are specified
	if ((($null -ne $PrivateData["ReleaseNotes"]) -and [string]::IsNullOrEmpty($PrivateData.ReleaseNotes)) -xor
		(($null -ne $PrivateData["Prerelease"]) -and [string]::IsNullOrEmpty($PrivateData.Prerelease)))
	{
		Write-Error -Category InvalidResult -TargetObject $HelpInfo `
			-Message "'$($Module.Name)' module does not specify either release of prerelease notes"
	}

	# Verify a module lists tags
	if ($null -eq $PrivateData.Tags)
	{
		Write-Error -Category InvalidResult -TargetObject $HelpInfo `
			-Message "'$($Module.Name)' module does not specify tags"
	}

	# Check no module with duplicate GUID exists among modules
	if ([array]::Find($GUID, [System.Predicate[string]] { $ThisGUID -eq $args[0] }))
	{
		Write-Error -Category InvalidData -TargetObject $ThisGUID -Message "Duplicate GUID '$ThisGUID' in '$Manifest' manifest"
	}

	# Add current module GUID to cache
	$GUID += $ThisGUID

	#
	# Check all module files are listed in manifest
	#

	# Get all files listed in module manifest
	$ListedFiles = foreach ($File in $Module.FileList)
	{
		[string] $Parent = "$ProjectRoot\Modules\$($Module.Name)"
		$File.Remove(0, $Parent.Length + 1)
	}

	# Get all module directories excluding auto generated directories for help content
	$Directories = Get-ChildItem -Path "$ProjectRoot\Modules\$($Module.Name)" -Recurse -Attributes Directory -Exclude "Content", "External"
	# Add module root directory
	$Directories += Get-Item -Path "$ProjectRoot\Modules\$($Module.Name)"

	# Get files from each module directory
	[string[]] $ModuleFiles = @()
	foreach ($Directory in $Directories.FullName)
	{
		$DirectoryFiles = Get-ChildItem -Path "$Directory\*" -File |
		Select-Object -ExpandProperty FullName

		[string] $Parent = "$ProjectRoot\Modules\$($Module.Name)"
		foreach ($File in $DirectoryFiles)
		{
			$ModuleFiles += $File.Remove(0, $Parent.Length + 1)
		}
	}

	# Verify each file is listed
	foreach ($ModuleFile in $ModuleFiles)
	{
		if ($ModuleFile -notin $ListedFiles)
		{
			Write-Error -Category InvalidData -TargetObject $ModuleFile `
				-Message "Module file '$ModuleFile' not listed in '$Manifest' manifest"
		}
		# Perform case sensitive comparison
		elseif ($ModuleFile -cnotin $ListedFiles)
		{
			Write-Warning -Message "[$ThisScript] Module file '$ModuleFile' was listed in '$Manifest' manifest but file path is not case sensitive"
		}
	}

	# Verify no redundant file is listed in module manifest
	foreach ($ListedFile in $ListedFiles)
	{
		if ($ListedFile -notin $ModuleFiles)
		{
			Write-Error -Category InvalidData -TargetObject $ModuleFile `
				-Message "Module manifest lists a file '$ListedFile' which does not exist in $($Module.Name) directory"
		}
		elseif ($ListedFile -cnotin $ModuleFiles)
		{
			Write-Warning -Message "[$ThisScript] Module manifest lists a file '$ListedFile' from $($Module.Name) directory but specification is not case sensitive"
		}
	}
}

#
# Check digital signature of binary files
#

$Dlls = Get-ChildItem -Name -Recurse -Path "$ProjectRoot\Modules" -Filter "*.dll"
[string[]] $DllPath = @()
foreach ($DLL in $Dlls)
{
	$DllPath += $DLL.Insert(0, "$ProjectRoot\Modules\")
}

Get-AuthenticodeSignature -FilePath $DllPath | Select-Object -Property StatusMessage, Path

Update-Log
Exit-Test
