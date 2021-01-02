
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

<#
.SYNOPSIS
Script template

.DESCRIPTION
A detailed description of the script.
This keyword can be used only once in each topic.

.PARAMETER ParameterName
The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the script syntax.

.EXAMPLE
A sample command that uses the script, optionally followed by sample output and a description.
Repeat this keyword for each example.

.INPUTS
The Microsoft .NET Framework types of objects that can be piped to the script.
You can also include a description of the input objects.

.OUTPUTS
The .NET Framework type of the objects that the cmdlet returns.
You can also include a description of the returned objects.

.NOTES
Additional information about the script.
NOTE: All of the features of function parameters, including the Parameter attribute and its named arguments,
are also valid in scripts.
NOTE: The OutputType attribute identifies the .NET Framework types returned by a cmdlet, function, or script.
NOTE: Script help can be preceded in the script only by comments and blank lines.
NOTE: If the first item in the script body (after the help) is a function declaration,
there must be at least two blank lines between the end of the script help and the function declaration.

.LINK
The name of a related topic.
The value appears on the line below the ".LINK" keyword and must be
preceded by a comment symbol # or included in the comment block.

Repeat the .LINK keyword for each related topic.
This content appears in the Related Links section of the help topic.

The .LINK keyword content can also include a Uniform Resource Identifier (URI)
to an online version of the same help topic.

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
The user role for the help topic.
This content appears when the Get-Help command includes the Role parameter of Get-Help.
-Role parameter displays help customized for the specified user role.
The role that the user plays in an organization.

.FUNCTIONALITY
The intended use of the function. This content appears when the Get-Help command includes
the Functionality parameter of Get-Help.
-Functionality parameter displays help for items with the specified functionality.
#>

[CmdletBinding()]
[OutputType([void])]
param ()

#region Initialization
#Requires -Version 5.1
# TODO: Adjust path to project settings and elevation requirement
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

# Check requirements
Initialize-Project -Abort
Write-Debug -Message "[$ThisScript] params($($PSBoundParameters.Values))"

# Imports
# TODO: Include modules and scripts as needed
. $PSScriptRoot\ContextSetup.ps1

# User prompt
# TODO: Update command line help messages
$Accept = "Template accept help message"
$Deny = "Skip operation, template deny help message"
# TODO: Replace TemplateContext variable
Update-Context $TemplateContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

Update-Log
