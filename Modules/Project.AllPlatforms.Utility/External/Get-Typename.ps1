
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
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

<#
.SYNOPSIS
Returns .NET return type name for input object
.PARAMETER InputObject
System.Object
.EXAMPLE
Get-Process | Get-TypeName
.INPUTS
Any .NET object
.OUTPUTS
System.String type name
.NOTES
Original code link: https://github.com/gravejester/Communary.PASM

Modifications by metablaster:
Added check when object is null
Added comment based help
Removed unneeded parantheses
Added input type to parameter
#>
function Get-TypeName
{
	[CmdletBinding()]
    param (
		[Parameter(Mandatory = $true,
		ValueFromPipeline = $true)]
		[System.Object] $InputObject
	)

	if (!$InputObject)
	{
		# This is called only on pipeline
		Write-Warning "Input object is null, aborting"
		return $null
	}

	Write-Output ($InputObject | Get-Member).TypeName | Select-Object -Unique
}
