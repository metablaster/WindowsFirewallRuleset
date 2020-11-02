
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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

.PARAMETER InstallLocation
Program installation directory

.EXAMPLE
PS> Edit-Table "%ProgramFiles(x86)%\TeamViewer"

.INPUTS
None. You cannot pipe objects to Edit-Table

.OUTPUTS
None. Edit-Table does not generate any output

.NOTES
TODO: principal parameter?
TODO: search executable paths
#>
function Edit-Table
{
	[OutputType([void])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $InstallLocation
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Attempt to insert new entry into installation table"

	# Nothing to do if the path does not exist
	if (!(Test-Environment $InstallLocation))
	{
		# TODO: will be true also for user profile, we should try to fix the path if it leads to user profile instead of doing nothing.
		Write-Debug -Message "[$($MyInvocation.InvocationName)] $InstallLocation not found or invalid"
		return
	}

	# Check if input path leads to user profile
	if (Test-UserProfile $InstallLocation)
	{
		# Make sure user profile variables are removed
		$InstallLocation = Format-Path $InstallLocation

		# Create a row
		$Row = $InstallTable.NewRow()

		# TODO: checking if Principal exists
		# Get a list of users to choose from, 3rd element in the path is user name
		$Principal = Get-GroupPrincipal "Users" | Where-Object -Property User -EQ ($InstallLocation.Split("\"))[2]

		# Enter data into row
		$Row.ID = ++$RowIndex
		$Row.SID = $Principal.SID
		$Row.User = $Principal.User
		$Row.Account = $Principal.Account
		$Row.Computer = $Principal.Computer
		$Row.InstallLocation = $InstallLocation

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Editing table for $($Principal.Account) with $InstallLocation"

		# Add the row to the table
		$InstallTable.Rows.Add($Row)
	}
	else
	{
		$InstallLocation = Format-Path $InstallLocation

		# Not user profile path, so it applies to all users
		$Principal = Get-UserGroup -Computer $PolicyStore | Where-Object -Property Group -EQ "Users"

		# Create a row
		$Row = $InstallTable.NewRow()

		# Enter data into row
		$Row.ID = ++$RowIndex
		$Row.SID = $Principal.SID
		$Row.Group = $Principal.Group
		$Row.Computer = $Principal.Computer
		$Row.InstallLocation = $InstallLocation

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Editing table for $($Principal.Caption) with $InstallLocation"

		# Add the row to the table
		$InstallTable.Rows.Add($Row)
	}
}
