
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

<#
.SYNOPSIS
Creates a DataTable for an object

.DESCRIPTION
Creates a DataTable based on an object's properties.

.PARAMETER InputObject
One or more objects to convert into a DataTable

.PARAMETER NonNullable
A list of columns to set disable AllowDBNull on

.INPUTS
[PSObject[]] Any object can be piped to Out-DataTable

.OUTPUTS
[System.Data.DataTable]

.EXAMPLE
PS> Get-PSDrive | Out-DataTable

Creates a DataTable from the properties of Get-PSDrive

.EXAMPLE
PS> Get-Process | Select-Object Name, CPU | Out-DataTable

Get a list of processes and their CPU and create a datatable

.NOTES
Adapted from script by Marc van Orsouw and function from Chad Miller
Version History
v1.0  - Chad Miller - Initial Release
v1.1  - Chad Miller - Fixed Issue with Properties
v1.2  - Chad Miller - Added setting column datatype by property as suggested by emp0
v1.3  - Chad Miller - Corrected issue with setting datatype on empty properties
v1.4  - Chad Miller - Corrected issue with DBNull
v1.5  - Chad Miller - Updated example
v1.6  - Chad Miller - Added column datatype logic with default to string
v1.7  - Chad Miller - Fixed issue with IsArray
v1.8  - ramblingcookiemonster - Removed if($Value) logic.  This would not catch empty strings, zero, $false and other non-null items
							  - Added perhaps pointless error handling

Modifications by metablaster January 2021:
Updated formatting, casing and naming according to the rest of project
Updated comment based help
Convert inner function to scriptblock

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Out-DataTable.md

.LINK
https://github.com/RamblingCookieMonster/PowerShell
#>
function Out-DataTable
{
	[CmdletBinding(HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Out-DataTable.md")]
	[OutputType([System.Data.DataTable])]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[PSObject[]] $InputObject,

		[Parameter()]
		[string[]] $NonNullable = @()
	)

	begin
	{
		$Table = New-Object -TypeName System.Data.datatable
		$First = $true

		[scriptblock] $GetODTType =	{
			param ($Type)

			$Types = @(
				"System.Boolean"
				"System.Byte[]"
				"System.Byte"
				"System.Char"
				"System.Datetime"
				"System.Decimal"
				"System.Double"
				"System.Guid"
				"System.Int16"
				"System.Int32"
				"System.Int64"
				"System.Single"
				"System.UInt16"
				"System.UInt32"
				"System.UInt64"
			)

			if ($Types -contains $Type)
			{
				Write-Output $Type
			}
			else
			{
				Write-Output "System.String"
			}
		} # Get-Type
	}

	process
	{
		foreach ($Object in $InputObject)
		{
			$Row = $Table.NewRow()
			foreach ($Property in $Object.PsObject.Properties)
			{
				$Name = $Property.Name
				$Value = $Property.Value

				# RCM: what if the first property is not reflective of all the properties?  Unlikely, but...
				if ($First)
				{
					$Column = New-Object -TypeName System.Data.DataColumn
					$Column.ColumnName = $Name

					# If it's not DBNull or Null, get the type
					if (($Value -isnot [System.DBNull]) -and ($null -ne $Value))
					{
						$Column.DataType = [System.Type]::GetType( $(& $GetODTType $Property.TypeNameOfValue))
					}

					# Set it to nonnullable if specified
					if ($NonNullable -contains $Name )
					{
						$Column.AllowDBNull = $false
					}

					try
					{
						$Table.Columns.Add($Column)
					}
					catch
					{
						Write-Error "Could not add column $($Column | Out-String) for property '$Name' with value '$Value' and type '$($Value.GetType().FullName)':`n$_"
					}
				}

				try
				{
					# Handle arrays and nulls
					if ($Property.GetType().IsArray)
					{
						$Row.Item($Name) = $Value | ConvertTo-Xml -As String -NoTypeInformation -Depth 1
					}
					elseif ($null -eq $Value)
					{
						$Row.Item($Name) = [System.DBNull]::Value
					}
					else
					{
						$Row.Item($Name) = $Value
					}
				}
				catch
				{
					Write-Error "Could not add property '$Name' with value '$Value' and type '$($Value.GetType().FullName)'"
					continue
				}

				# Did we get a null or DBNull for a non-nullable item? let the user know.
				if ($NonNullable -contains $Name -and (($Value -is [System.DBNull]) -or ($null -eq $Value)))
				{
					Write-Verbose "NonNullable property '$Name' with null value found: $($object | Out-String)"
				}
			}

			try
			{
				$Table.Rows.Add($Row)
			}
			catch
			{
				Write-Error "Failed to add row '$($Row | Out-String)':`n$_"
			}

			$First = $false
		}
	}

	end
	{
		Write-Output $Table -NoEnumerate
	}
} # Out-DataTable
