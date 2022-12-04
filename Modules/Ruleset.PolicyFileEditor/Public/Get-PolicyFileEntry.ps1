
<#
NOTE: This file has been sublicensed by metablaster zebal@protonmail.ch
under a dual license of the MIT license AND the Apache license, see both licenses below
#>

<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

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
Apache License

Copyright (C) 2015 Dave Wyatt

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>

<#
.SYNOPSIS
Retrieves the current setting(s) from a .pol file.

.DESCRIPTION
Retrieves the current setting(s) from a .pol file.

.PARAMETER Path
Path to the .pol file that is to be read.

.PARAMETER Key
The registry key inside the .pol file that you want to read.

.PARAMETER ValueName
The name of the registry value.
May be set to an empty string to read the default value of a key.

.PARAMETER All
Switch indicating that all entries from the specified .pol file should be output,
instead of searching for a specific key\ValueName pair.

.EXAMPLE
Get-PolicyFileEntry -Path $env:systemroot\system32\GroupPolicy\Machine\registry.pol `
    -Key Software\Policies\Something -ValueName SomeValue

Reads the value of Software\Policies\Something\SomeValue from the Machine admin templates of the local GPO.
Either returns an object with the data and type of this registry value (if present),
or returns nothing, if not found.

.EXAMPLE
Get-PolicyFileEntry -Path $env:systemroot\system32\GroupPolicy\Machine\registry.pol -All

Outputs all of the registry values from the local machine Administrative Templates

.INPUTS
None. This command does not accept pipeline input.

.OUTPUTS
If the specified registry value is found, the function outputs a PSCustomObject with the following properties:
ValueName: The same value that was passed to the -ValueName parameter
Key: The same value that was passed to the -Key parameter
Data: The current value assigned to the specified Key\ValueName in the .pol file.
Type: The RegistryValueKind type of the specified Key\ValueName in the .pol file.
If the specified registry value is not found in the .pol file, the command returns nothing. No error is produced.

.NOTES
None.
#>
function Get-PolicyFileEntry
{
	[CmdletBinding(DefaultParameterSetName = "ByKeyAndValue")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $Path,

		[Parameter(Mandatory = $true, Position = 1, ParameterSetName = "ByKeyAndValue")]
		[string] $Key,

		[Parameter(Mandatory = $true, Position = 2, ParameterSetName = "ByKeyAndValue")]
		[string] $ValueName,

		[Parameter(Mandatory = $true, ParameterSetName = "All")]
		[switch] $All
	)

	# TODO: We should not use caller preferences since that's already inherited by ProjectSettings.ps1
	if (Get-Command Get-CallerPreference -CommandType ExternalScript)
	{
		& Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}

	try
	{
		$policyFile = Open-PolicyFile -Path $Path -ErrorAction Stop
	}
	catch
	{
		$PSCmdlet.ThrowTerminatingError($_)
	}

	if ($PSCmdlet.ParameterSetName -eq "ByKeyAndValue")
	{
		$Entry = $policyFile.GetValue($Key, $ValueName)

		if ($null -ne $Entry)
		{
			Convert-PolicyEntryToPsObject -PolicyEntry $Entry
		}
	}
	else
	{
		foreach ($Entry in $policyFile.Entries)
		{
			Convert-PolicyEntryToPsObject -PolicyEntry $Entry
		}
	}
}
