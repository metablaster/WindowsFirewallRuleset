
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
Create data table used to hold information for a list of programs

.DESCRIPTION
Create data table which is filled with data about programs and principals such
as users or groups and their SID for which given firewall rule applies
This method is primarily used to reset the table
Each entry in the table also has an ID to help choosing entries by ID

.PARAMETER Name
Table name

.EXAMPLE
PS> Initialize-Table

.INPUTS
None. You cannot pipe objects to Initialize-Table

.OUTPUTS
None. Initialize-Table does not generate any output

.NOTES
TODO: There should be a better way to drop the table instead of recreating it
TODO: We should initialize table with complete list of programs and principals and
return the table by reference
#>
function Initialize-Table
{
	[CmdletBinding()]
	[OutputType([void])]
	param (
		[Parameter()]
		[string] $Name = "InstallTable"
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# Create Table object
	if ($Develop)
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] resetting global installation table"
		Set-Variable -Name $Name -Scope Global -Value (New-Object -TypeName System.Data.DataTable $Name)
	}
	else
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] resetting local installation table"
		Set-Variable -Name $Name -Scope Script -Value (New-Object -TypeName System.Data.DataTable $Name)
	}

	Set-Variable -Name RowIndex -Scope Script -Value 0

	# Define Columns
	$ColumnID = New-Object -TypeName System.Data.DataColumn ID, ([int32])
	$ColumnUser = New-Object -TypeName System.Data.DataColumn User, ([string])
	$ColumnGroup = New-Object -TypeName System.Data.DataColumn Group, ([string])
	$ColumnDomain = New-Object -TypeName System.Data.DataColumn Domain, ([string])
	$ColumnPrincipal = New-Object -TypeName System.Data.DataColumn Principal, ([string])
	$ColumnSID = New-Object -TypeName System.Data.DataColumn SID, ([string])
	$ColumnInstallLocation = New-Object -TypeName System.Data.DataColumn InstallLocation, ([string])

	# Add the Columns
	$InstallTable.Columns.Add($ColumnID)
	$InstallTable.Columns.Add($ColumnUser)
	$InstallTable.Columns.Add($ColumnGroup)
	$InstallTable.Columns.Add($ColumnDomain)
	$InstallTable.Columns.Add($ColumnPrincipal)
	$InstallTable.Columns.Add($ColumnSID)
	$InstallTable.Columns.Add($ColumnInstallLocation)
}
