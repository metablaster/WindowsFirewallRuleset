
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

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
None.
TODO: Update Copyright and start implementing module function
TODO: Update HelpURI
#>
function Add-WindowsPSModulePath
{
	[CmdletBinding(SupportsShouldProcess)]
	[OutputType([void])]
	param ()

	if ($PSVersionTable.PSEdition -eq 'Core' -and -not $IsWindows)
	{
		throw "This cmdlet is only supported on Windows"
	}

	if ($PSVersionTable.PSEdition -eq 'Desktop')
	{
		return
	}

	$paths = @(
		$Env:PSModulePath -split [System.IO.Path]::PathSeparator
		"${Env:UserProfile}\Documents\WindowsPowerShell\Modules"
		"${Env:ProgramFiles}\WindowsPowerShell\Modules"
		"${Env:WinDir}\system32\WindowsPowerShell\v1.0\Modules"
		[System.Environment]::GetEnvironmentVariable('PSModulePath',
			[System.EnvironmentVariableTarget]::User) -split [System.IO.Path]::PathSeparator
		[System.Environment]::GetEnvironmentVariable('PSModulePath',
			[System.EnvironmentVariableTarget]::Machine) -split [System.IO.Path]::PathSeparator
	)

	$pathTable = [ordered] @{}

	foreach ($path in $paths)
	{
		if ($pathTable[$path])
		{
			continue
		}

		if ($PSCmdlet.ShouldProcess($path, "Add to PSModulePath"))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Adding '$path' to the PSModulePath."
			$pathTable[$path] = $true
		}
	}

	$Env:PSModulePath = $pathTable.Keys -join [System.IO.Path]::PathSeparator
}