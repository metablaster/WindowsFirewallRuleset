
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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
Manually add new program installation directory to the table

.DESCRIPTION
Based on path and if it's valid path fill the table with it and add principals and other information
Module scope installation table is updated

.PARAMETER LiteralPath
Program installation directory

.PARAMETER Domain
Remote computer for which installation path is added to the table

.PARAMETER Quiet
If specified suppresses warning, error or informationall messages if specified path does not exist
or if it's of an invalid syntax needed for firewall

.EXAMPLE
PS> Edit-Table "%ProgramFiles(x86)%\TeamViewer"

.INPUTS
None. You cannot pipe objects to Edit-Table

.OUTPUTS
None. Edit-Table does not generate any output

.NOTES
TODO: principal parameter?
TODO: search executable paths
TODO: This function should make use of Out-DataTable function from Ruleset.Utility module
#>
function Edit-Table
{
	[CmdletBinding()]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true)]
		[Alias("InstallLocation")]
		[string] $LiteralPath,

		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter()]
		[switch] $Quiet
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	# Replace localhost and dot with NETBIOS computer name
	if (($Domain -eq "localhost") -or ($Domain -eq "."))
	{
		$Domain = [System.Environment]::MachineName
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Attempt to insert new entry into installation table"

	# Check if input path leads to user profile and is compatible with firewall
	if (Test-FileSystemPath $LiteralPath -UserProfile -Firewall -Quiet -PathType Directory -Domain $Domain)
	{
		[string] $SystemDrive = Get-CimInstance -Class Win32_OperatingSystem -CimSession $CimServer |
		Select-Object -ExpandProperty SystemDrive

		# Get a list of users to choose from, 3rd element in the path is user name
		# NOTE: | Where-Object -Property User -EQ ($LiteralPath.Split("\"))[2]
		# will not work if a path is inconsistent with back or forward slashes
		$UserInfo = Get-GroupPrincipal "Users" -Domain $Domain | Where-Object {
			$LiteralPath -match "^$SystemDrive\\+Users\\+$($_.User)\\+"
		}

		# Make sure user profile variables are not present
		$LiteralPath = Format-Path $LiteralPath

		# Create a row
		$Row = $InstallTable.NewRow()

		# Enter data into row
		$Row.ID = ++$RowIndex
		$Row.Domain = $UserInfo.Domain
		$Row.User = $UserInfo.User
		$Row.Group = $UserInfo.Group
		$Row.Principal = $UserInfo.Principal
		$Row.SID = $UserInfo.SID
		$Row.InstallLocation = $LiteralPath

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Editing table for $($UserInfo.Principal) with $LiteralPath"

		# Add the row to the table
		$InstallTable.Rows.Add($Row)
	}
	# Check if input path is valid for firewall, since this path is manually specified by developer
	# in Search-Installation we need to test it just like in Confirm-Installation where path is
	# manually specified by the user
	elseif (Test-FileSystemPath $LiteralPath -Firewall -PathType Directory -Quiet:$Quiet -Domain $Domain)
	{
		$LiteralPath = Format-Path $LiteralPath

		# Not user profile path, so it applies to all users
		$UserInfo = Get-UserGroup -Domain $Domain | Where-Object -Property Group -EQ "Users"

		# Create a row
		$Row = $InstallTable.NewRow()

		# Enter data into row
		$Row.ID = ++$RowIndex
		$Row.Domain = $UserInfo.Domain
		$Row.Group = $UserInfo.Group
		$Row.Principal = $UserInfo.Principal
		$Row.SID = $UserInfo.SID
		$Row.InstallLocation = $LiteralPath

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Editing table for $($UserInfo.Principal) with $LiteralPath"

		# Add the row to the table
		$InstallTable.Rows.Add($Row)
	}
	else
	{
		# TODO: will be true also for user profile, we should try to fix the path if it leads to user profile instead of doing nothing.
		# NOTE: This may be best done with Format-Path by reformatting
		Write-Debug -Message "[$($MyInvocation.InvocationName)] $LiteralPath not found or invalid"
		return
	}
}
