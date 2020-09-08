
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2016 Øyvind Kallstad
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

# NOTE: File must be UTF-8 with BOM to preserve unicode character from Copyright

<#
.SYNOPSIS
Returns .NET return type name for input object
.DESCRIPTION
Unlike Get-Member commandlet returns only type name, and if
there are multiple type names chooses unique ones only.
.PARAMETER InputObject
Target object for which to retrieve type name
.EXAMPLE
Get-Process | Get-TypeName
.INPUTS
System.Object Any .NET object
.OUTPUTS
[string] type name or null
.NOTES
Original code link: https://github.com/gravejester/Communary.PASM
TODO: need better checking for input, on pipeline.
TODO: needs testing for arrays vs single objects, it doesn't look right
Modifications by metablaster year 2020:
Added check when object is null
Added comment based help
Removed unneeded parentheses
Added input type to parameter
#>
function Get-TypeName
{
	# TODO: make Diagnostics look like this in all files
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
		"PSUseProcessBlockForPipelineCommand", "", Justification = "Must not be used here")]
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.AllPlatforms.Utility/Help/en-US/Get-TypeName.md")]
	param (
		[Parameter(Mandatory = $true,
			ValueFromPipeline = $true)]
		[System.Object] $InputObject
	)

	if ($null -eq $InputObject)
	{
		# This is called only on pipeline
		Write-Warning "Input object is null, aborting"
		return $null
	}

	Write-Output ($InputObject | Get-Member).TypeName | Select-Object -Unique
}
