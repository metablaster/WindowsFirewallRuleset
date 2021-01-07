
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2015 Warren Frame

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

.VERSION 0.9.1

.GUID 0186fc8f-feff-44f7-84a9-4053993ef6a2

.AUTHOR Warren Frame
#>

<#
.SYNOPSIS
Get exported types in the current session

.DESCRIPTION
List all exported types in the current session, allowing you to filter on module, assembly,
fullname, namespace, basetype, and whether a type is an enum.

.PARAMETER Module
Filter on Module.
Wildcard characters are supported.

.PARAMETER Assembly
Filter on Assembly.
Wildcard characters are supported.

.PARAMETER FullName
Filter on FullName.
Wildcard characters are supported.

.PARAMETER Namespace
Filter on Namespace.
Wildcard characters are supported.

.PARAMETER BaseType
Filter on BaseType.
Wildcard characters are supported.

.PARAMETER IsEnum
Filter on IsEnum.

.EXAMPLE
PS> Get-ExportedType -IsEnum | Select -ExpandProperty FullName | Sort -Unique

Will list the full name of all Enums in the current session

.EXAMPLE
Connect to a web service and list all the exported types

Connect to the web service, give it a namespace we can search on
PS> $weather = New-WebServiceProxy -uri "http://www.webservicex.net/globalweather.asmx?wsdl" -Namespace GlobalWeather

Search for the namespace
PS> Get-ExportedType -NameSpace GlobalWeather

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     False    MyClass1ex_net_globalweather_asmx_wsdl   System.Object
True     False    GlobalWeather                            System.Web.Services.Protocols.SoapHttpClientProtocol
True     True     GetWeatherCompletedEventHandler          System.MulticastDelegate
True     False    GetWeatherCompletedEventArgs             System.ComponentModel.AsyncCompletedEventArgs
True     True     GetCitiesByCountryCompletedEventHandler  System.MulticastDelegate
True     False    GetCitiesByCountryCompletedEventArgs     System.ComponentModel.AsyncCompletedEventArgs

.INPUTS
None. You cannot pipe objects to Get-ExportedType.ps1

.OUTPUTS
[System.RuntimeType]

.NOTES
Modifications by metablaster January 2021:
Added Parameter and SupportsWildcards attributes to parameters
Updated formatting and casing according to the rest of project
Convert to script by removing function
Rename from Get-Type to Get-ExportedType
Added links and notes to comment based help

.LINK
https://github.com/metablaster/WindowsFirewallRuleset

.LINK
https://github.com/RamblingCookieMonster/PowerShell
#>
[CmdletBinding()]
[OutputType([System.RuntimeType])]
param (
	[Parameter()]
	[SupportsWildcards()]
	[string] $Module = "*",

	[Parameter()]
	[SupportsWildcards()]
	[string] $Assembly = "*",

	[Parameter()]
	[SupportsWildcards()]
	[string] $FullName = "*",

	[Parameter()]
	[SupportsWildcards()]
	[string] $Namespace = "*",

	[Parameter()]
	[SupportsWildcards()]
	[string] $BaseType = "*",

	[Parameter()]
	[switch] $IsEnum
)

# Build up the Where statement
$WhereArray = @('$_.IsPublic')
if ($Module -ne "*") { $WhereArray += '$_.Module -like $Module' }
if ($Assembly -ne "*") { $WhereArray += '$_.Assembly -like $Assembly' }
if ($FullName -ne "*") { $WhereArray += '$_.FullName -like $FullName' }
if ($Namespace -ne "*") { $WhereArray += '$_.Namespace -like $Namespace' }
if ($BaseType -ne "*") { $WhereArray += '$_.BaseType -like $BaseType' }
# This clause is only evoked if IsEnum is passed in
if ($PSBoundParameters.ContainsKey("IsEnum")) { $WhereArray += '$_.IsENum -like $IsENum' }

# Give verbose output, convert where string to scriptblock
$WhereString = $WhereArray -Join " -and "
$WhereBlock = [scriptblock]::Create( $WhereString )
Write-Verbose "Where ScriptBlock: { $WhereString }"

# Invoke the search
[AppDomain]::CurrentDomain.GetAssemblies() | ForEach-Object {
	Write-Verbose "Getting types from $($_.FullName)"
	try
	{
		$_.GetExportedTypes()
	}
	catch
	{
		Write-Verbose "$($_.FullName) error getting Exported Types: $_"
		$null
	}
} | Where-Object -FilterScript $WhereBlock
