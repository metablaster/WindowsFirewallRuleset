
<#
MIT License

Copyright (c) 2019, 2020 metablaster zebal@protonmail.ch

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

#
# Remove loaded modules and removable variables, usefull for module debugging
#

# Set to true to indicate development phase, force unloading modules and removing variables
$Develop = $true

if ($Develop)
{
	Write-Host "DEBUG: Clean up environment" -ForegroundColor Yellow -BackgroundColor Black
	Remove-Module -Name System -ErrorAction Ignore
	Remove-Variable -Name SystemCheck -Scope Global -Force -ErrorAction Ignore

	Remove-Module -Name FirewallModule -ErrorAction Ignore
	Remove-Variable -Name WarningStatus -Scope Global -ErrorAction Ignore
	Remove-Variable -Name Debug -Scope Global -Force -ErrorAction Ignore
	Remove-Variable -Name Execute -Scope Global -ErrorAction Ignore

	Remove-Module -Name Test -ErrorAction Ignore
	Remove-Module -Name UserInfo -ErrorAction Ignore
	Remove-Module -Name ComputerInfo -ErrorAction Ignore

	Remove-Module -Name ProgramInfo -ErrorAction Ignore
	Remove-Variable -Name InstallTable -Scope Global -ErrorAction Ignore
}
