
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

function Save-PolicyFile
{
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSProvideCommentHelp", "",
		Scope = "Function", Justification = "This is 3rd party code which needs to be studied")]
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true)]
		[TJX.PolFileEditor.PolFile] $PolicyFile,

		[Parameter()]
		[switch] $UpdateGptIni
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if ($PSCmdlet.ShouldProcess($PolicyFile.FileName, "Save new settings"))
	{
		$ParentPath = Split-Path $PolicyFile.FileName -Parent

		if (-not (Test-Path -LiteralPath $ParentPath -PathType Container))
		{
			try
			{
				New-Item -Path $ParentPath -ItemType Directory -ErrorAction Stop -Confirm:$false -WhatIf:$false | Out-Null
			}
			catch
			{
				$ErrorRecord = $_
				$Message = "Error creating parent folder of path '$Path': $($errorRecord.Exception.Message)"
				$Exception = New-Object System.Exception($Message, $ErrorRecord.Exception)

				$NewErrorRecord = New-Object System.Management.Automation.ErrorRecord(
					$Exception, "CreateParentFolderError", $ErrorRecord.CategoryInfo.Category, $Path
				)

				throw $NewErrorRecord
			}
		}

		try
		{
			$PolicyFile.SaveFile()
		}
		catch
		{
			$ErrorRecord = $_
			$Message = "Error saving policy file to path '$($PolicyFile.FileName)': $($ErrorRecord.Exception.Message)"
			$Exception = New-Object System.Exception($Message, $ErrorRecord.Exception)

			$NewErrorRecord = New-Object System.Management.Automation.ErrorRecord(
				$Exception, "FailedToSavePolicyFile", [System.Management.Automation.ErrorCategory]::OperationStopped, $PolicyFile
			)

			throw $NewErrorRecord
		}
	}

	if ($UpdateGptIni)
	{
		if (($PolicyFile.FileName -match "^(.*)\\+([^\\]+)\\+[^\\]+$") -and
			(($Matches[2] -eq "User") -or ($Matches[2] -eq "Machine")))
		{
			$IniPath = Join-Path $Matches[1] GPT.ini

			if (Test-Path -LiteralPath $IniPath -PathType Leaf)
			{
				Update-GptIniVersion -Path $IniPath -PolicyType $Matches[2] # -Confirm:$false -WhatIf:$false
			}
			else
			{
				New-GptIni -Path $IniPath -PolicyType $Matches[2] # -Confirm:$false -WhatIf:$false
			}
		}
	}
}
