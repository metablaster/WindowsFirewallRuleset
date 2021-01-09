
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2018, 2019 Microsoft Corporation. All rights reserved

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
Appends the existing Windows PowerShell PSModulePath to existing PSModulePath

.DESCRIPTION
If the current PSModulePath does not contain the Windows PowerShell PSModulePath,
it will be appended to the end.

.EXAMPLE
PS> Add-WindowsPSModulePath
PS> Import-Module Hyper-V

.EXAMPLE
PS> Add-WindowsPSModulePath
PS> Get-Module -ListAvailable

.INPUTS
None. You cannot pipe objects to Add-WindowsPSModulePath

.OUTPUTS
None. Add-WindowsPSModulePath does not generate any output

.NOTES
Following modifications by metablaster November 2020:

- Added comment based help based on original comments
- Code formatting according to the rest of project design
- Added HelpURI link to project location

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Add-WindowsPSModulePath.md

.LINK
https://github.com/PowerShell/WindowsCompatibility
#>
function Add-WindowsPSModulePath
{
	[CmdletBinding(SupportsShouldProcess = $true,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Add-WindowsPSModulePath.md")]
	[OutputType([void])]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if ($PSVersionTable.PSEdition -eq "Core" -and -not $IsWindows)
	{
		throw "This cmdlet is only supported on Windows"
	}

	if ($PSVersionTable.PSEdition -eq "Desktop")
	{
		return
	}

	$ModuleDirectory = @(
		$Env:PSModulePath -split [System.IO.Path]::PathSeparator
		"${Env:UserProfile}\Documents\WindowsPowerShell\Modules"
		"${Env:ProgramFiles}\WindowsPowerShell\Modules"
		"${Env:WinDir}\system32\WindowsPowerShell\v1.0\Modules"
		[System.Environment]::GetEnvironmentVariable("PSModulePath",
			[System.EnvironmentVariableTarget]::User) -split [System.IO.Path]::PathSeparator
		[System.Environment]::GetEnvironmentVariable("PSModulePath",
			[System.EnvironmentVariableTarget]::Machine) -split [System.IO.Path]::PathSeparator
	)

	$PathTable = [ordered] @{}

	foreach ($PathEntry in $ModuleDirectory)
	{
		if ($PathTable[$PathEntry])
		{
			continue
		}

		if ($PSCmdlet.ShouldProcess($PathEntry, "Add to PSModulePath"))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Adding '$PathEntry' to the PSModulePath."
			$PathTable[$PathEntry] = $true
		}
	}

	$Env:PSModulePath = $PathTable.Keys -join [System.IO.Path]::PathSeparator
}
