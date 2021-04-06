
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

TODO: Update Copyright date and author
Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

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

# TODO: Update script metadata, see Templates\New-PSScriptInfo.ps1 for details
# NOTE: Run [guid]::NewGuid() to generate new guid
<#PSScriptInfo

.VERSION 0.10.1

.GUID 66e38822-834d-4a90-b9c6-9e600a472a0a

.AUTHOR metablaster zebal@protonmail.com

.COPYRIGHT Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

.TAGS Template

.LICENSEURI https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/master/LICENSE

.PROJECTURI https://github.com/metablaster/WindowsFirewallRuleset

.RELEASENOTES https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Readme/CHANGELOG.md
#>

<#
.SYNOPSIS
A brief description of the function or script.

.DESCRIPTION
A detailed description of the function or script.

.PARAMETER ParameterName
The description of a parameter.
Add a ".PARAMETER" keyword for each parameter in the function or script.

.EXAMPLE
A sample command that uses the function or script, optionally followed by sample output and a description.
Repeat this keyword for each example.

.INPUTS
The Microsoft .NET Framework types of objects that can be piped to the function or script.
You can also include a description of the input objects.

.OUTPUTS
The .NET Framework type of the objects that the cmdlet returns.
You can also include a description of the returned objects.

.NOTES
Additional information about the function or script.

Script and comment based help design rules:
1. All of the features of function parameters, including the Parameter attribute and its named
arguments, are also valid in scripts.
2. The script can have begin/process/end blocks to provide pipeline supprot but there can be no
statement outside the B/P/E blocks except param block, using directive and #Requires statements.
3. The #Requires statements can appear on any line in a script
4. A "using" statement must appear before any other statements in a script.
5. The OutputType attribute identifies the .NET Framework types returned by a cmdlet, function, or script.
6. Script help can be preceded in the script only by comments and blank lines, #Requires statements
can be considered also as "comments" in this context.
7. For script help, if the first item in the script body (after the help) is a function declaration,
there must be at least two blank lines between the end of the script help and the function declaration.
8. For function help, there cannot be more than one blank line between the last line of the function
help and the function keyword.
9. There must be at least one blank line between the last non-help comment line and the beginning of
the comment-based help.

.LINK
The name of a related topic.
The value appears on the line below the ".LINK" keyword and must be preceded by a comment symbol #
or included in the comment block.

Repeat the .LINK keyword for each related topic.
This content appears in the Related Links section of the help topic.

The .LINK keyword content can also include a Uniform Resource Identifier (URI) to an online version
of the same help topic.

The online version opens when you use the Online parameter of Get-Help.
The URI must begin with "http" or "https".

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-7

.LINK
https://docs.microsoft.com/en-us/powershell/scripting/developer/help/examples-of-comment-based-help?view=powershell-7

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/get-help?view=powershell-7

.COMPONENT
The technology or feature that the script uses, or to which it is related.
This content appears when the Get-Help command includes the Component parameter of Get-Help.
-Component parameter displays commands with the specified component value, such as "Exchange"

.ROLE
The name of the user role for the help topic.
This content appears when the Get-Help command includes the Role parameter of Get-Help.
-Role parameter displays help customized for the specified user role.
The role that the user plays in an organization.

.FUNCTIONALITY
The keywords that describe the intended use of the function.
This content appears when the Get-Help command includes the Functionality parameter of Get-Help.
-Functionality parameter displays help for items with the specified functionality.
#>

# TODO: Remove using statement and/or elevation requirement
using namespace System
#Requires -Version 5.1
#Requires -RunAsAdministrator

# NOTE: surpress script scope warning example
[Diagnostics.CodeAnalysis.SuppressMessageAttribute( # Scope = "Function"
	"PSAvoidUsingWriteHost", "", Justification = "Script scope supression")]
[CmdletBinding()]
[OutputType([void])]
param (
	# NOTE: surpress parameter example
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
		"PSReviewUnusedParameter", "Force", Justification = "This will work for functions only")]
	[Parameter()]
	[switch] $Force
)

#region Initialization
# TODO: Adjust path to project settings
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
. $PSScriptRoot\ContextSetup.ps1
Initialize-Project -Strict

# User prompt
# TODO: Update command line help messages
$Accept = "Template accept help message"
$Deny = "Skip operation, template deny help message"
# TODO: Replace TemplateContext variable
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

# NOTE: surpress variable example
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
	"PSReviewUnusedParameter", "", Justification = "Template")]
$UnusedVariable = $null

Update-Log
