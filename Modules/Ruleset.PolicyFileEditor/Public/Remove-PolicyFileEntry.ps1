
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
Removes a value from a .pol file.

.DESCRIPTION
Removes a value from a .pol file.
By default, also updates the version number in the policy's gpt.ini file.

.PARAMETER Path
Path to the .pol file that is to be modified.

.PARAMETER Key
The registry key inside the .pol file from which you want to remove a value.

.PARAMETER ValueName
The name of the registry value to be removed.
May be set to an empty string to remove the default value of a key.

.PARAMETER NoGptIniUpdate
When this switch is used, the command will not attempt to update the version number in the gpt.ini file

.EXAMPLE
Remove-PolicyFileEntry -Path $env:systemroot\system32\GroupPolicy\Machine\registry.pol `
    -Key Software\Policies\Something -ValueName SomeValue

Removes the value Software\Policies\Something\SomeValue from the local computer Machine GPO, if present.
Updates the Machine version counter in $env:systemroot\system32\GroupPolicy\gpt.ini

.EXAMPLE
$Entries = @(
    New-Object psobject -Property @{ ValueName = 'MaxXResolution'; Data = 1680 }
    New-Object psobject -Property @{ ValueName = 'MaxYResolution'; Data = 1050 }
)
$Entries | Remove-PolicyFileEntry -Path $env:SystemRoot\system32\GroupPolicy\Machine\registry.pol `
    -Key 'SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'

Example of using pipeline input to remove multiple values at once.
The advantage to this approach is that the .pol file on disk (and the GPT.ini file) will be updated
if _any_ of the specified settings had to be removed, and will be left alone if the file already
did not contain any of those values.

The Key property could have also been specified via the pipeline objects instead of on the command line,
but since both values shared the same Key, this example shows that you can pass the value in either way.

.INPUTS
The Key and ValueName properties may be bound via the pipeline by property name.

.OUTPUTS
None. This command does not generate output.

.NOTES
If the specified policy file is already not present in the .pol file,
the file will not be modified, and the gpt.ini file will not be updated.
#>
function Remove-PolicyFileEntry
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $Path,

		[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)]
		[string] $Key,

		[Parameter(Mandatory = $true, Position = 2, ValueFromPipelineByPropertyName = $true)]
		[string] $ValueName,

		[switch] $NoGptIniUpdate
	)

	begin
	{
		# TODO: We should not use caller preferences since that's already inherited by ProjectSettings.ps1
		if (Get-Command Get-CallerPreference -CommandType ExternalScript)
		{
			& Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		}

		$Dirty = $false

		try
		{
			$policyFile = Open-PolicyFile -Path $Path -ErrorAction Stop
		}
		catch
		{
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}

	process
	{
		if ($PSCmdlet.ShouldProcess("Group policy *.pol file", "Delete file entry"))
		{
			$Entry = $policyFile.GetValue($Key, $ValueName)

			if ($null -eq $Entry)
			{
				Write-Verbose "Entry '$Key\$ValueName' is already not present in file '$Path'"
				return
			}

			Write-Verbose "Removing entry '$Key\$ValueName' from file '$Path'"
			$policyFile.DeleteValue($Key, $ValueName)
			$dirty = $true
		}
	}

	end
	{
		if ($Dirty)
		{
			$DoUpdateGptIni = -not $NoGptIniUpdate

			try
			{
				# Save-PolicyFile contains the calls to $PSCmdlet.ShouldProcess, and will inherit our
				# WhatIfPreference / ConfirmPreference values from here.
				Save-PolicyFile -PolicyFile $policyFile -UpdateGptIni:$doUpdateGptIni -ErrorAction Stop
			}
			catch
			{
				$PSCmdlet.ThrowTerminatingError($_)
			}
		}
	}
}
