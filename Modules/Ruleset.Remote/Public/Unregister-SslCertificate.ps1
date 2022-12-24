
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021, 2022 metablaster zebal@protonmail.ch

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
Unregister SSL certificate for CIM and PowerShell remoting

.DESCRIPTION
Unregister-SslCertificate uninstalls SSL certificate and undoes changes
previously done by Register-SslCertificate

.PARAMETER CertThumbprint
Certificate thumbprint which is to be uninstalled

.PARAMETER Force
If specified, no prompt to remove certificate from certificate store is shown

.EXAMPLE
PS> Unregister-SslCertificate

.INPUTS
None. You cannot pipe objects to Unregister-SslCertificate

.OUTPUTS
None. Unregister-SslCertificate does not generate any output

.NOTES
TODO: Does not undo registration with WinRM listener
#>
function Unregister-SslCertificate
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Unregister-SslCertificate.md")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true)]
		[ValidatePattern("^[0-9a-f]{40}$")]
		[string] $CertThumbprint,

		[Parameter()]
		[switch] $Force
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if ($PSCmdlet.ShouldProcess("Certificate store", "Uninstall certificate $CertThumbprint"))
	{
		$Cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {
			$_.Thumbprint -eq $CertThumbprint
		}

		if (!$Cert)
		{
			Write-Error -Category ObjectNotFound `
				-Message "Certificate with the specified thumbprint '$CertThumbprint' was not found"
			return
		}

		Get-ChildItem Cert:\LocalMachine\My |
		Where-Object { $_.Thumbprint -eq $CertThumbprint } | Remove-Item -Force:$Force

		Get-ChildItem Cert:\LocalMachine\Root |
		Where-Object { $_.Thumbprint -eq $CertThumbprint } | Remove-Item -Force:$Force
	}
}
