
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2016 Warren Frame

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

<#PSScriptInfo

.VERSION 0.13.0

.GUID 2c773cf4-f1d4-4e05-a4f0-6ff5ea8eb454

.AUTHOR Warren Frame
#>

<#
.SYNOPSIS
Get type for properties of one or more objects

.DESCRIPTION
Extract unique .NET types for properties of one or more objects.
This method can prove useful to detect inconsistent property types in a
collection of generated objects where the same property type is expected.

.PARAMETER InputObject
Get properties and their types for each of these

.PARAMETER Property
If specified, only return unique types for these properties

.EXAMPLE
Define an array of sample objects:

PS> $Array = [PSCustomObject]@{
	Property1 = "har"
	Property2 = $(get-date)
},
[PSCustomObject]@{
	Property1 = "bar"
	Property2 = 2
}

Get property types from sample array.
In this example, Property1 is always a System.String, Property2 is a System.DateTime and System.Int32
PS> $Array | Get-PropertyType

	Name  Value
	----  -----
	Property1 {System.String}
	Property2 {System.DateTime, System.Int32}

Pretend Property2 should always be a DateTime, extract all objects from $Array where this is not the case
PS> $Array | Where-Object { $_.Property2 -isnot [System.DateTime] }

	prop1 prop2
	----- -----
	bar       2

.INPUTS
[PSCustomObject]

.OUTPUTS
[hashtable]

.NOTES
Modifications by metablaster January 2021:
Added #Requires statement, Parameter and OutputType attributes
Updated formatting, casing and naming according to the rest of project
Convert to script by removing function
Added links, inputs, outputs and notes to comment based help
Replaced PSObject entries with PSCustomObject
Added SuppressMessageAttribute for false positive

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts

.LINK
https://github.com/RamblingCookieMonster/PowerShell
#>

#Requires -Version 5.1

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
	"PSReviewUnusedParameter", "Property", Justification = "False positive")]
[CmdletBinding(PositionalBinding = $false)]
[OutputType([hashtable])]
param (
	[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
	[PSCustomObject] $InputObject,

	[Parameter()]
	[string[]] $Property = $null
)

begin
{
	<#
	.SYNOPSIS
	Gets property order for specified object

	.DESCRIPTION
	Gets property order for specified object.
	Function to extract properties

	.PARAMETER InputObject
	A single object to convert to an array of property value pairs.

	.PARAMETER Membertype
	Membertypes to include

	.PARAMETER ExcludeProperty
	Specific properties to exclude
	#>
	function Get-PropertyOrder
	{
		[CmdletBinding()]
		param (
			[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromRemainingArguments = $false)]
			[PSCustomObject] $InputObject,

			[Parameter()]
			[ValidateSet("AliasProperty", "CodeProperty", "Property", "NoteProperty",
				"ScriptProperty", "Properties", "PropertySet", "Method", "CodeMethod",
				"ScriptMethod", "Methods", "ParameterizedProperty", "MemberSet", "Event",
				"Dynamic", "All")]
			[string[]] $MemberType = @(
				"NoteProperty"
				"Property"
				"ScriptProperty"
			),

			[Parameter()]
			[string[]] $ExcludeProperty
		)

		begin
		{
			if ($PSBoundParameters.ContainsKey("InputObject"))
			{
				$FirstObject = $InputObject[0]
			}
		}
		process
		{
			# We only care about one object...
			$FirstObject = $InputObject
		}
		end
		{
			# Get properties that meet specified parameters
			$FirstObject.PSObject.Properties |
			Where-Object { $MemberType -contains $_.MemberType } |
			Select-Object -ExpandProperty Name |
			Where-Object { !$ExcludeProperty -or ($ExcludeProperty -notcontains $_) }
		}
	} # Get-PropertyOrder

	[hashtable] $Result = @{}
}

process
{
	foreach ($ObjectEntry in $InputObject)
	{
		# Extract the properties in this object
		$AllProperties = @(Get-PropertyOrder -InputObject $ObjectEntry |
			Where-Object { !$Property -or $Property -contains $_ } )

		foreach ($PropEntry in $AllProperties)
		{
			try
			{
				$Type = $ObjectEntry.$PropEntry.GetType().FullName
			}
			catch
			{
				$Type = $null
			}

			# Check to see if we already have types for this prop
			if (!$Result.ContainsKey($PropEntry))
			{
				# We don't have an array yet, start one, put the type in it
				$List = New-Object System.Collections.ArrayList
				$List.Add($Type) | Out-Null
				$Result.Add($PropEntry, $List)
			}
			elseif ($Result[$PropEntry] -notcontains $Type)
			{
				# Type isn't in the array yet, add it
				$Result[$PropEntry].Add($Type) | Out-Null
			}
		}
	}
}

end
{
	Write-Output $Result
}
