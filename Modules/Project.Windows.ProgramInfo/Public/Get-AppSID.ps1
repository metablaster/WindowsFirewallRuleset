
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
Get store app SID

.DESCRIPTION
Get SID for single store app if the app exists

.PARAMETER UserName
Username for which to query app SID

.PARAMETER AppName
"PackageFamilyName" string

.EXAMPLE
PS> Get-AppSID "User" "Microsoft.MicrosoftEdge_8wekyb3d8bbwe"

.INPUTS
None. You cannot pipe objects to Get-AppSID

.OUTPUTS
[System.String] store app SID (security identifier) if app found

.NOTES
TODO: Test if path exists
TODO: remote computers?
#>
function Get-AppSID
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.Windows.ProgramInfo/Help/en-US/Get-AppSID.md")]
	[OutputType([string])]
	param (
		[Alias("User")]
		[Parameter(Mandatory = $true)]
		[string] $UserName,

		[Parameter(Mandatory = $true)]
		[string] $AppName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	$TargetPath = "C:\Users\$UserName\AppData\Local\Packages\$AppName\AC"
	if (Test-Path -PathType Container -Path $TargetPath)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SID for app: $AppName"

		# TODO: what if nothing is returned?
		$ACL = Get-Acl $TargetPath
		$ACE = $ACL.Access.IdentityReference.Value

		foreach ($Entry in $ACE)
		{
			# NOTE: avoid spamming
			# Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing: $Entry"

			# package SID starts with S-1-15-2-
			if ($Entry -match "S-1-15-2-")
			{
				return $Entry
			}
		}
	}
	else
	{
		Write-Warning -Message "Store app '$AppName' is not installed by user '$UserName' or the app is missing"
		Write-Information -Tags "User" -MessageData "INFO: To fix the problem let this user update all of it's apps in Windows store"
	}
}
