
<#
.SYNOPSIS
Validates Windows user credentials.

.DESCRIPTION
Validates a [PSCredential] instance representing user-account credentials
against the current user's logon domain or local machine.

.PARAMETER Credential
The [PSCredential] instance to validate, typically obtained with
Get-Credential.

The .UserName value may be:
* a mere username: e.g, "user"
* prefixed with a NETBIOS domain name (NTLM format): e.g., "domain\user"
* in UPN format: e.g., "user@domain.example.org"

IMPORTANT:
If the logon domain is the current machine, validation happens against the local user database.

IRRESPECTIVE OF THE DOMAIN NAME SPECIFIED, VALIDATION IS ONLY EVER PERFORMED
AGAINST THE CURRENT USER'S LOGON DOMAIN.

If an NTLM-format username is specified, the NETBIOS domain prefix, if specified,
must match the NETBIOS logon domain as reflected in $env:USERDOMAIN

If a UPN-format username is specified, its domain suffix should match $env:USERDNSDOMAIN,
although if it doesn't, only a warning is issued and an attempt to validate against the
logon domain is still attempted, so as to support UPNs whose domain suffix differs from
the logon DNS name.
To avoid the warning, use the NTLM-format username with the NETBIOS domain prefix,
or omit the domain part altogether.

If the credentials are valid in principle, but using them with the target account is
in effect not possible - such as due to the account being disabled or having expired -
a warning to that effect is issued and $false is returned.

The SecureString instance containing the decrypted password in the input credentials is
decrypted *in local memory*, though it is again encrypted *in transit* when querying
Active Directory.

.PARAMETER Local
Use this switch to validate perform validation against the local machine's
user database rather than against the current logon domain.

If you're not currently logged on to a domain, use of this switch is
optional.
Conversely, however, the only way to validate against a domain
is to be logged on to it.

.EXAMPLE
PS> Test-Credential -Credential user
True

Prompts for the password for user "user" and validates it against the current
logon domain (which may be the local machine). 'True' ($True) as the output
indicates successful validation.

.EXAMPLE
PS> Test-Credential domain\user

Prompts for the password for user "domain\user" and validates it against
the current logon domain, whose NETBIOS name (as reflected in $env:USERDOMAIN)
must match.

.EXAMPLE
PS> Test-Credential user@domain.example.org

Prompts for the password for user "user@domain.example.org" and validates it against
the current logon domain, whose DNS name (as reflected in $env:USERDNSDOMAIN)
is expected to match; if not, a warning is issued, but validation is still
attempted.

.EXAMPLE
PS> Test-Credential Administrator -Local

Prompts for the password of the machine-local administrator account and
validates it against the local user database.

.OUTPUTS
[bool] A Boolean indicating whether the credentials were successfully validated.

.NOTES
Gratefully adapted from:
https://gallery.technet.microsoft.com/scriptcenter/Test-Credential-dda902c6,
via https://stackoverflow.com/q/10802850/45375
WinAPI solution for local-account validation inspired by:
https://stackoverflow.com/a/15644447/45375

.LINK
https://gist.github.com/mklement0/83e8e6a2b39ecec7b0a14a8e631769ce
#>
function Test-Credential
{
	# NOTE: SuppressMessageAttribute not working for manual analyzer run, type disabled in PSScriptAnalyzerSettings
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
		"PSUseCompatibleTypes", "", Scope = "Function", Justification = "PS 5.1.17763 is out of date")]
	[CmdletBinding(PositionalBinding = $false)]
	[OutputType([bool])]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[System.Management.Automation.CredentialAttribute()]
		[PSCredential] $Credential,

		[Parameter()]
		[switch] $Local
	)

	$ErrorActionPreference = "Stop"

	# NETBIOS domain name or local machine name.
	$LogonDomain = [System.Environment]::UserDomainName
	$UserName = $Credential.UserName
	$IsUpn = $Credential.UserName -match "@"
	# A domain contained $Credential.UserName, if any, extracted below.
	$SpecifiedDomain = ""
	# See if we're logged on to an actual domain or just to the local machine...
	$LoggedOnToDomain = $env:COMPUTERNAME -ne [System.Environment]::UserDomainName

	# ... and set the validation context accordingly.
	$ContextType = (
		# Local account - not actually used; see below.
		[System.DirectoryServices.AccountManagement.ContextType]::Machine,
		# AD DS
		[System.DirectoryServices.AccountManagement.ContextType]::Domain
	)[$LoggedOnToDomain -and -not $Local]

	# Extract the domain-name portion, if any, from the username.
	# Recognizes formats NTLM (domain\username) and UPN (username@dns.domain)
	if ($Credential.UserName -match "^[^\\]+(?=\\)|(?<=@).+$")
	{
		$SpecifiedDomain = $Matches[0]
		# NOTE: We must pass a mere username to .ValidateCredentials below.
		# .GetNetworkCredential().UserName conveniently strips the NTLM-style
		# domain prefix, but we must strip the UPN-style suffix manually.
		$UserName = $Credential.GetNetworkCredential().UserName -replace "@.+$"
	}

	# If a domain name was specified, validate it.
	if ($SpecifiedDomain)
	{
		if ($Local -and $SpecifiedDomain -ne $env:COMPUTERNAME)
		{
			throw "You've requested validation of machine-local credentials with -Local, so your username must not have a domain component that differs from the local machine name."
		}
		elseif (-not $IsUpn -and $SpecifiedDomain -ne $LogonDomain)
		{
			throw "Specified NETBIOS domain prefix ($SpecifiedDomain) does not match the logon domain ($LogonDomain)."
		}
		elseif ($IsUpn -and -not $LoggedOnToDomain)
		{
			throw "You've specified a UPN, but you're not logged on to a domain: $($Credential.UserName)"
		}
		elseif ($IsUpn -and $SpecifiedDomain -ne $env:USERDNSDOMAIN)
		{
			Write-Warning -Message @"
You've specified a UPN, but its domain-name part ($SpecifiedDomain) does not match the logon DNS domain name ($env:USERDNSDOMAIN).
Proceeding on the assumption that the UPN still refers to an account in the logon domain.
To avoid this warning, use the NTLM username form ($env:USERDOMAIN\$UserName),
or omit the domain part altogether ($UserName).
"@
		}
	}

	Write-Verbose -Message ("Validating: " + (@{
				UserName = $UserName
				Domain = $LogonDomain
				ContextType = $ContextType
			} | Out-String))

	if ($Local -or -not $LoggedOnToDomain)
	{
		# LOCAL account
		# !! System.DirectoryServices.AccountManagement.PrincipalContext with non-domain-joined machines with context 'Machine' doesn't work
		# !! reliably - can result in the following exception:
		# !!   Multiple connections to a server or shared resource by the same user, using more than one user name, are not allowed. Disconnect all previous
		# !!   connections to the server or shared resource and try again.
		# Therefore, we use the WinAPI's LogonUser function instead, which requires compiling a helper type on demand.
		(Add-Type -PassThru -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace net.same2u.util
{
    public class WinCredentialHelper
    {

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool LogonUser(string lpszUsername, string lpszDomain, string lpszPassword, int dwLogonType, int dwLogonProvider, out IntPtr phToken);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool CloseHandle(IntPtr hObject);

        // Validates the specified credentials (username and password) agains the account database of the specified domain,
        // which defaults to the current domain or, for non-domain-joined machines, the local machine.
        // Note: Strictly speaking, the ability to log on locally, at the time of the call is tested;
        //       especially in domain environments, incidental restrictions such as time of day or what workstations a user may log on to
        //       could prevent logon, even if the credentials are valid in principle.
        //       See the error codes at https://docs.microsoft.com/en-us/windows/win32/debug/system-error-codes--1300-1699-, starting with 1326 (ERROR_LOGON_FAILURE).
        public static bool Validate(string username, string password, string domain = "")
        {
            IntPtr hToken = IntPtr.Zero;
            if (domain == String.Empty) domain = System.Environment.GetEnvironmentVariable("USERDOMAIN");
            // Note: * On a machine not connected to a domain, the domain parameter is seemingly IGNORED.
            //       * In a domain environment:
            //           * to explicitly target only the local user-account database, pass "." for `domain`.
            //           * if you pass null for `domain`, `username` must be in UPN format (user@domain.com)
            bool ok = LogonUser(username, domain, password, 3 /*LOGON32_LOGON_NETWORK*/, 0 /*LOGON32_PROVIDER_DEFAULT*/, out hToken);
            // int lastErr = Marshal.GetLastWin32Error(); Console.WriteLine(lastErr);
            if (hToken != IntPtr.Zero) CloseHandle(hToken);
            return ok;
        }
    }
}
'@)::Validate($UserName, $Credential.GetNetworkCredential().password)
	}
	else
	{
		# DOMAIN == AD DS account.
		# Note: While .GetNetworkCredential().password retrieves the *plain-text* password *locally*, the *connection
		#       to AD* (in the case of [System.DirectoryServices.AccountManagement.ContextType]::Domain) is
		#       encrypted, because "When the context options are not specified by the application,
		#         the Account Management API uses the following combination of options:
		#           ContextOptions.Negotiate | ContextOptions.Signing | ContextOptions.Sealing
		#       " - https://docs.microsoft.com/en-us/dotnet/api/system.directoryservices.accountmanagement.contextoptions
		$PrincipalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext $ContextType, $LogonDomain

		try
		{
			$PrincipalContext.ValidateCredentials($UserName, $Credential.GetNetworkCredential().password)
		}
		catch
		{
			# An exception occurring in .ValidateCredentials() often suggests that the credentials were valid in principle,
			# but there's a problem with the *account*, such as it being disabled or
			# the password having expired; we return $False in that case, but issue a *warning*
			# with the cause of the problem.
			# !! However, it can also indicate the inability to connect to the server.
			# Note: The underlying exception message is wrapped as follows, so we must extract it:
			#          Exception calling "ValidateCredentials" with "2" argument(s): "<msg>"<newline>
			Write-Warning -Message ($_.Exception.Message -replace "\r?\n" -split '"' -ne "")[-1]

			# Output $False, given that *in effect* the credentials do not work.
			$false
		}
		finally
		{
			$PrincipalContext.Dispose()
		}
	}
}
