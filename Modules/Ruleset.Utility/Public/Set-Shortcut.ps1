
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

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
Set desktop or online shortcut

.DESCRIPTION
Create or set shortcut to file or online location.
Optionally set shortcut properties such as the icon, hotkey or description.

.PARAMETER Name
The name of a schortcut file, optionally with an extension.
Use the .lnk extension for a file system shortcut.
Use the .url extension for an Internet shortcut.

.PARAMETER Path
The full path (excluding file name) to location of the shortcut file you want to create.
Alternatively one of the following keywords can be specified:
"AllUsersDesktop"
"AllUsersStartMenu"
"AllUsersPrograms"
"AllUsersStartup"
"Desktop"
"Favorites"
"Fonts"
"MyDocuments"
"NetHood"
"PrintHood"
"Programs"
"Recent"
"SendTo"
"StartMenu"
"Startup"
"Templates"

.PARAMETER TargetPath
The full path and filename of the location that the shortcut file will open.

.PARAMETER URL
URL of the location that the shortcut file will open.

.PARAMETER IconLocation
Full pathname of the icon file to set on shortcut.

.PARAMETER IconIndex
Index is the position of the icon within the file (where the first icon is 0)

.PARAMETER Description
Specify description of the shortcut

.PARAMETER Hotkey
A string value of the form "Modifier + Keyname",
where Modifier is any combination of Alt, Ctrl, and Shift, and Keyname is one of A through Z or 0 through 12.

.PARAMETER WindowStyle
Specify how the application window will appear

.PARAMETER WorkingDirectory
Sets the path of the shortcut's working directory

.PARAMETER Arguments
Optionally set arguments to target file

.PARAMETER Admin
If specified, the shortcut is run as Administrator

.EXAMPLE
PS> Set-Shortcut -Path "$env:Home\Desktop\test.lnk" -TargetPath "C:\Windows\program.exe"

.EXAMPLE
PS> Set-Shortcut -Path "$env:Home\Desktop\test.lnk" -TargetPath "C:\Windows\program.exe" -Admin -Index 16

.INPUTS
None. You cannot pipe objects to Set-Shortcut

.OUTPUTS
None. Set-Shortcut does not generate any output

.NOTES
None.
#>
function Set-Shortcut
{
	[CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true, ConfirmImpact = "High",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Set-Shortcut.md")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidatePattern("^\w+(\.[lnk|url])?")]
		[string] $Name,

		[Parameter(Mandatory = $true)]
		[System.IO.DirectoryInfo] $Path,

		[Parameter(Mandatory = $true, ParameterSetName = "Local")]
		[Alias("Source")]
		[ValidatePattern('^[a-z]:\\(?:[^\\/:*?"<>|\r\n]+\\)*[^\\/:*?"<>.|\r\n]*\.\w{3}$')]
		[System.IO.FileInfo] $TargetPath,

		[Parameter(Mandatory = $true, ParameterSetName = "Online")]
		[Alias("Link")]
		[ValidatePattern("[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)")]
		[uri] $URL,

		[Parameter()]
		[Alias("Icon")]
		[System.IO.FileInfo] $IconLocation,

		[Parameter()]
		[Alias("Index")]
		[ValidateRange([int32]::MinValue, [int32]::MaxValue)]
		[int32] $IconIndex,

		[Parameter(ParameterSetName = "Local")]
		[string] $Description,

		[Parameter()]
		[string] $Hotkey,

		[Parameter(ParameterSetName = "Local")]
		[ValidateSet("Normal", "Minimized", "Maximized")]
		[string] $WindowStyle,

		[Parameter(ParameterSetName = "Local")]
		[ValidatePattern('^[a-z]:\\(?:[^\\/:*?"<>|\r\n]+\\)*[^\\/:*?"<>.|\r\n]*$')]
		[System.IO.FileInfo] $WorkingDirectory,

		[Parameter(ParameterSetName = "Local")]
		[Alias("ArgumentList")]
		[string] $Arguments,

		[Parameter(ParameterSetName = "Local")]
		[switch] $Admin
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if ($URL) { $Target = $URL.Authority }
	else { $Target = Split-Path -Path $TargetPath -Leaf }

	if ($PSCmdlet.ShouldProcess($Path, "Set shortcut to '$Target'"))
	{
		$SpecialFolders = @(
			"AllUsersDesktop"
			"AllUsersStartMenu"
			"AllUsersPrograms"
			"AllUsersStartup"
			"Desktop"
			"Favorites"
			"Fonts"
			"MyDocuments"
			"NetHood"
			"PrintHood"
			"Programs"
			"Recent"
			"SendTo"
			"StartMenu"
			"Startup"
			"Templates")

		$InformationPreference = "Continue"
		[System.IO.FileInfo] $FilePath = $null
		$WshShell = New-Object -ComObject WScript.Shell

		# Check and initialize the path to shortcut file
		if ($Path -in $SpecialFolders)
		{
			$FilePath = $WshShell.SpecialFolders($Path)

			if ([string]::IsNullOrEmpty($FilePath))
			{
				Write-Error -Category InvalidResult -TargetObject $Path -Message "Failed to resolve special folder: $Path"
				return
			}
		}
		elseif (Test-Path -Path $Path -PathType Container)
		{
			$FilePath = $Path.FullName.TrimEnd("\")
		}
		else
		{
			Write-Error -Category ObjectNotFound -TargetObject $Path -Message "The specified path was not found: $Path"
			return
		}

		# Ensure shortcut extension is present
		if ($URL)
		{
			$Extension = ".url"
		}
		else
		{
			$Extension = ".lnk"
		}

		if ([string]::IsNullOrEmpty($(Split-Path -Path $Name -Extension)))
		{
			$Name += $Extension
			Write-Warning -Message "Shortcut extension implicitly set to *$Extension"
		}
		elseif (($URL -and $Name -notmatch "\.url$") -or ($TargetPath -and $Name -notmatch "\.lnk$"))
		{
			if ($Name -notmatch "\.\w+$")
			{
				Write-Error -Category InvalidResult -TargetObject $Name -Message "Shortcut extension not recognized"
				return
			}

			$Name = $Name -replace $Matches[0], $Extension
			Write-Warning -Message "Shortcut extension *$($Matches[0]) replaced with *$Extension"
		}

		$FilePath = "$($FilePath.FullName)\$Name"

		# If creating shortcut to file ensure target file exists
		if ($TargetPath)
		{
			if (!(Test-Path -Path $TargetPath -PathType Leaf))
			{
				Write-Error -Category ObjectNotFound -TargetObject $TargetPath -Message "Target file not found: $TargetPath"
				return
			}
		}

		try
		{
			$Shortcut = $WshShell.CreateShortcut($FilePath)
		}
		catch
		{
			Write-Error -Category $_.CategoryInfo.Category -TargetObject $_.TargetObject -Message $_.Exception.Message
			return
		}

		# Set target file or URL
		if ($URL)
		{
			$Shortcut.TargetPath = $URL.OriginalString
		}
		else
		{
			$Shortcut.TargetPath = $TargetPath
		}

		# Optionally set shortcut icon
		if (![string]::IsNullOrEmpty($IconLocation))
		{
			if (Test-Path -Path $IconLocation -PathType Leaf)
			{
				if ($IconIndex)
				{
					# ex. %SystemRoot%\System32\Shell32.dll,-19
					$IconLocation = $IconLocation.FullName + ",$IconIndex"
				}

				try
				{
					# TODO: Property is present in url shortcut
					$Shortcut.IconLocation = $IconLocation
				}
				catch
				{
					Write-Warning -Message "Setting icon location not implemented. $($_.Exception.Message)"
				}
			}
			else
			{
				Write-Warning -Message "Unable to locate icon file: $IconLocation"
			}
		}

		# Optionally set keyboard shortcut to target file
		if ($Hotkey)
		{
			try
			{
				# TODO: Property is present in url shortcut
				$Shortcut.Hotkey = $Hotkey
			}
			catch
			{
				Write-Warning -Message "Setting hotkey not implemented. $($_.Exception.Message)"
			}
		}

		# Following properties are valid for file system shortcuts only
		# NOTE: Internet shortcuts support only two properties: FullName and TargetPath (the URL target).
		if ($TargetPath)
		{
			# Optionally set shortcut description
			# NOTE: The name of an URL shortcut is an actual description
			if (![string]::IsNullOrEmpty($Description))
			{
				$Shortcut.Description = $Description
			}

			# Optionally set target file working directory
			if ($WorkingDirectory)
			{
				if (Test-Path -Path $WorkingDirectory -PathType Container)
				{
					$Shortcut.WorkingDirectory = $WorkingDirectory
				}
				else
				{
					Write-Warning -Message "Working directory skipped because it does not exist"
				}
			}

			# Optionally set target file argument list
			if ($Arguments)
			{
				$Shortcut.Arguments = $Arguments
			}

			# Optionally set how will the target file display
			if ($WindowStyle)
			{
				$Shortcut.WindowStyle = switch ($WindowStyle)
				{
					"Normal" { 1; break }
					"Minimized" { 2; break }
					"Maximized" { 3; break }
				}
			}
		}

		if ($FilePath.Exists)
		{
			Write-Information -MessageData "INFO: Updating shortcut '$FilePath'"
		}
		else
		{
			Write-Information -MessageData "INFO: Creating shortcut '$FilePath'"
		}

		# Create or update shortcut file
		try
		{
			# TODO: Verify file system permissions
			$Shortcut.Save()
		}
		catch
		{
			Write-Warning -Message "Lacking file system permissions is likely reason for failure"
			Write-Error -Category $_.CategoryInfo.Category -TargetObject $_.TargetObject -Message $_.Exception.Message
			return
		}

		# Not valid for URL shortcuts
		if ($Admin)
		{
			# Optionally set Run as Administrator checkbox
			$Bytes = [System.IO.File]::ReadAllBytes($FilePath)

			# set byte 21 (0x15) bit 6 (0x20) ON
			$Bytes[0x15] = $Bytes[0x15] -bor 0x20
			[System.IO.File]::WriteAllBytes($FilePath, $Bytes)
		}
	}
}
