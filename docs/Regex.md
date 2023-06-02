
# Regex expressions for quick reference

A list of regex expressions which are used to:

- Filter firewall logs
- Perform bulk operations on rules with VSCode.

For example once your regex hits, you would use `CTRL + SHIFT + L` to enter [Multi cursor][multicursor]\
mode and manipulate all regex matches however you like.

Reserved regex characters that must be escaped: `[ ] ( ) . \ ^ $ | ? * + { }`

## Table of Contents

- [Regex expressions for quick reference](#regex-expressions-for-quick-reference)
  - [Table of Contents](#table-of-contents)
  - [Filterline](#filterline)
    - [Programs](#programs)
    - [DHCPv6](#dhcpv6)
    - [DHCPv4](#dhcpv4)
    - [LLMNRv4](#llmnrv4)
  - [Firewall rules](#firewall-rules)
    - [Get -DisplayName parameter and it's value](#get--displayname-parameter-and-its-value)
    - [Get platform](#get-platform)
    - [Get group](#get-group)
    - [Get Interface](#get-interface)
    - [Get policy store](#get-policy-store)
    - [Get Profile property if value also contains variable names](#get-profile-property-if-value-also-contains-variable-names)
    - [Direction protocol pairs](#direction-protocol-pairs)
    - [Get local and remote port parameters and values](#get-local-and-remote-port-parameters-and-values)
    - [Get mapping pairs and their values](#get-mapping-pairs-and-their-values)
    - [Get LocalUser and EdgeTraversalPolicy](#get-localuser-and-edgetraversalpolicy)
    - [Get local and remote IPv6 address only in any notation](#get-local-and-remote-ipv6-address-only-in-any-notation)
    - [Get local and remote IPv4 address only in any notation](#get-local-and-remote-ipv4-address-only-in-any-notation)
    - [Get owner and package for store app](#get-owner-and-package-for-store-app)
    - [Get enabled or action flag](#get-enabled-or-action-flag)
  - [Random regexes](#random-regexes)
    - [File system path validation](#file-system-path-validation)
    - [File path selection](#file-path-selection)
    - [URL validation](#url-validation)
    - [DACL validation](#dacl-validation)
    - [UNC validation](#unc-validation)
    - [UPN validation](#upn-validation)
    - [User profile validation](#user-profile-validation)
    - [File extension](#file-extension)
    - [File name](#file-name)
    - [NETBIOS name](#netbios-name)
    - [System environment variable](#system-environment-variable)
    - [Email validation](#email-validation)
    - [IPv6 validation](#ipv6-validation)
    - [IPv4 validation](#ipv4-validation)
    - [Match comment block in script](#match-comment-block-in-script)
    - [SHA1 thumbprint validation](#sha1-thumbprint-validation)
    - [GUID validation](#guid-validation)

## Filterline

Filterline regexes are to be used in `.vscode\filterline.json` to filter out firewall logs.\
Note that the syntax for filterline regex expressions is java script.

### Programs

```regex
"DROP TCP.*([0-9]{1,3}\\.){3}[0-9]{1,3}\\s\\d+\\s(80|443)"
```

### DHCPv6

```regex
"DROP UDP.*([a-f0-9:]+:)+[a-f0-9]+\\s(547|546)"
```

### DHCPv4

```regex
"DROP UDP.*([0-9]{1,3}\\.){3}[0-9]{1,3}\\s(67|68)"
```

### LLMNRv4

```regex
"DROP UDP.*([0-9]{1,3}\\.){3}[0-9]{1,3}\\s\\d+(?<!5353)\\s5353"
```

[Table of Contents](#table-of-contents)

## Firewall rules

Note:

- Firewall rule examples here are shortened.
- Each regex includes an optional space at the end

### Get -DisplayName parameter and it's value

In the example below multi cursor-ing all the matches in a script would allow to cut and paste all
regex matches onto a second line by using CTRL + X, Down Arrow to move and CTRL + V.

```powershell
New-NetFirewallRule -DisplayName "Interface-Local Multicast" -Service Any `
New-NetFirewallRule -DisplayName $_.Name -Service Any `
```

```regex
-DisplayName "(.*)"(?= -Service) ?
-DisplayName ("(.*)"|\$_\.\w+)(?= -Service) ?
```

[//]: # (Platform)

[Table of Contents](#table-of-contents)

### Get platform

```powershell
-Platform $Platform
```

```regex
-Platform \$Platform ?
```

### Get group

```powershell
New-NetFirewallRule -Group $Group
New-NetFirewallRule -Group "Some rule group"
```

```regex
-Group (([\$|\w]\w+)|(".*")) ?
```

[Table of Contents](#table-of-contents)

### Get Interface

```powershell
New-NetFirewallRule -InterfaceType $DefaultInterface
New-NetFirewallRule -InterfaceType "Wired, Wireless"
# TODO: is this valid? if yes regex needs update
New-NetFirewallRule -InterfaceType Wired, Wireless
```

```regex
-InterfaceType (([\$|\w]\w+)|(".*")) ?
```

[//]: # (PolicyStore)

[Table of Contents](#table-of-contents)

### Get policy store

```powershell
-PolicyStore $PolicyStore
```

```regex
-PolicyStore [\$|\w]\w+ ?
```

[Table of Contents](#table-of-contents)

### Get Profile property if value also contains variable names

```powershell
New-NetFirewallRule -Profile Any
New-NetFirewallRule -Profile $DefaultProfile
New-NetFirewallRule -Profile Private, Domain
```

```regex
-Profile [\$|\w]\w+,? ?\w+ ?
```

[Table of Contents](#table-of-contents)

### Direction protocol pairs

```powershell
New-NetFirewallRule -Direction $Direction -Protocol UDP
New-NetFirewallRule -Direction Inbound -Protocol 41
-Direction $Direction -Protocol ICMPv6 -IcmpType 12
-Direction $Direction -Protocol ICMPv4 -IcmpType 3:4
```

```regex
-Direction [\$|\w]\w+ -Protocol [\$|\w]\w+ ?
-Direction [\$|\w]\w+ -Protocol [\$|\w]\w+ -IcmpType \d+(:\d+)? ?
 ```

[Table of Contents](#table-of-contents)

### Get local and remote port parameters and values

```powershell
New-NetFirewallRule -LocalPort Any -RemotePort 547, 53
New-NetFirewallRule -LocalPort 546 -RemotePort IPHTTPSout
New-NetFirewallRule -LocalPort 22, 546-55, 54 -RemotePort Any
```

```regex
-LocalPort [\w&&,&&\-&& ]+ -RemotePort [\w&&,&&\-&& ]+ ?
```

[Table of Contents](#table-of-contents)

### Get mapping pairs and their values

```powershell
New-NetFirewallRule -LocalOnlyMapping $false -LooseSourceMapping $false
New-NetFirewallRule -LocalOnlyMapping $true -LooseSourceMapping $false
```

```regex
-LocalOnlyMapping \$(false|true) -LooseSourceMapping \$(false|true) ?
 ```

[//]: # (If needed)

[Table of Contents](#table-of-contents)

### Get LocalUser and EdgeTraversalPolicy

```powershell
# TODO: can also be function call for SDDL
New-NetFirewallRule -LocalUser $UsersGroupSDDL -EdgeTraversalPolicy DeferToApp
New-NetFirewallRule -LocalUser Any -EdgeTraversalPolicy DeferToApp
```

```regex
-LocalUser [\$|\w]\w+ ?
-LocalUser [\$|\w]\w+ -EdgeTraversalPolicy \w+ ?
```

[Table of Contents](#table-of-contents)

### Get local and remote IPv6 address only in any notation

```powershell
New-NetFirewallRule -LocalAddress ff01::/16 -RemoteAddress Any
New-NetFirewallRule -LocalAddress Any -RemoteAddress ff01::2
```

```regex
-LocalAddress (?!.*\.)[\w&&:&&/]+ -RemoteAddress (?!.*\.)[\w&&:&&/]+ ?
```

[Table of Contents](#table-of-contents)

### Get local and remote IPv4 address only in any notation

```powershell
New-NetFirewallRule -LocalAddress 224.3.0.44, 224.0.0.0-224.0.0.255, 224.3.0.44 -RemoteAddress Any
New-NetFirewallRule -LocalAddress LocalSubnet4 -RemoteAddress 224.3.0.44, 224.0.0.0-224.0.0.255
New-NetFirewallRule -LocalAddress LocalSubnet4 -RemoteAddress 224.3.0/24, 224.0/16-224.0.0.255
```

```regex
-LocalAddress (?!.*:)[,\.\w \-/]+ -RemoteAddress (?!.*:)[,\.\w \-/]+ ?
```

[Table of Contents](#table-of-contents)

### Get owner and package for store app

```powershell
New-NetFirewallRule -Owner (Get-GroupSID "Administrators") -Package "*"
New-NetFirewallRule -Owner $Principal.SID -Package $PackageSID
```

```regex
-Owner [\$|\w](\w|\.)+(?= -Package) -Package [\$|\w](\w|\.)+ ?
-Owner (([\$|\w](\w|\.)+)|(\(.*\))) -Package ([\$|\w](\w|\.)+|".*") ?
```

[Table of Contents](#table-of-contents)

### Get enabled or action flag

```regex
-Enabled (True|False) ?
-Action (Allow|Block) ?
```

[Table of Contents](#table-of-contents)

## Random regexes

### File system path validation

Here file extention must be either `*.lnk` or `*.url`

```powershell
'^[a-z]:\\(?:[^\\/:*?"<>|\r\n]+\\)*[^\\/:*?"<>.|\r\n]*(\.(lnk|url))*$'
```

[Table of Contents](#table-of-contents)

### File path selection

Select path up to last directory, up to 3rd directory and last item respectively

```powershell
".+?(?=\\.*)"
".+?(?=(\\.*\\*){3})"
"\\+(?:.(?!\\))+$"
```

[Table of Contents](#table-of-contents)

### URL validation

Regex breakdown:

```regex
(
https?:\/\/(www\.)?
[a-zA-Z0-9@:%._\+~#=]{2,256}
\.[a-z]{2,6}
\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)
(\([^(]+\))?
)
```

```powershell
"https?:\/\/(www\.)?[a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)"
```

Sample match:

```none
https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-2000-server/bb726984
```

```powershell
"https?:\/\/(www\.)?[a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)(\([^(]+\))?"
```

Sample match:

```none
https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-2000-server/bb726984(v=technet.10)
```

[Table of Contents](#table-of-contents)

### DACL validation

DACL is part of SDDL string

```powershell
"(D:\w*(\((\w*;\w*){4};((S(-\d+){2,12})|[A-Z]*)\))+){1}"
```

[Table of Contents](#table-of-contents)

### UNC validation

Universal Name Convention

```powershell
"^\\\\[a-zA-Z0-9\.\-_]{1,}(\\[a-zA-Z0-9\-_\s\.]{1,}){1,}[\$]{0,1}"
```

[Table of Contents](#table-of-contents)

### UPN validation

Universal Principal Name\
UPN name invalid characters: ~ ! # $ % ^ & * ( ) + = [ ] { } \ / | ; : " < > ? ,

Domain name portion:

```powershell
"(?(\[)(\[(\d{1,3}\.){3}\d{1,3}\])|(([0-9a-zA-Z][-0-9a-zA-Z]*[0-9a-zA-Z]*\.)+[0-9a-zA-Z][-0-9a-zA-Z]{0,22}[0-9a-zA-Z]))$"
```

[Table of Contents](#table-of-contents)

### User profile validation

```powershell
"^($env:SystemDrive\\?|\\)Users(?!\\+Public\\*)"
```

[Table of Contents](#table-of-contents)

### File extension

Invalid characters to name a directory: / \ : < > ? * | "

```powershell
'\.[^./\\:<>?*|"]+$'
```

[Table of Contents](#table-of-contents)

### File name

Invalid characters to name a file: / \ : < > ? * | "

```powershell
'[^/\\:<>?*|"]+$'
```

[Table of Contents](#table-of-contents)

### NETBIOS name

The first character of the name must not be asterisk `*`\
Any character less than a space (0x20) is invalid.\
Microsoft allows the dot and space character may work too.\
NETBIOS invalid characters: " / \ [ ] : | < > + = ; ,

```powershell
"^([A-Z0-9\-_]\*?)+$"
```

Relaxed version for Windows:

```powershell
"^([A-Z0-9a-z\-_\.\s]\*?)+$"
```

[Table of Contents](#table-of-contents)

### System environment variable

The first character of the name must not be numeric.
A variable name may include any of the following characters:

```none
A-Z, a-z, 0-9, # $ ' ( ) * + , - . ? @ [ ] _ ` { } ~
```

[Table of Contents](#table-of-contents)

### Email validation

2 useful links:

- [Microsoft][msemail]
- [stackoverflow][stackemail]

[Table of Contents](#table-of-contents)

### IPv6 validation

Simple version:

```none
([a-f0-9:]+:)+[a-f0-9]+
```

For more complex examples see [Regular expression that matches valid IPv6 addresses][ipv6 regex]

[Table of Contents](#table-of-contents)

### IPv4 validation

Simple version:

```none
([0-9]{1,3}\.){3}[0-9]{1,3}
```

For regex below all credits to [Validating IPv4 addresses with regexp][ipv4 regex]

```none
\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}\b
```

### Match comment block in script

function comment:

```regex
\<#[\s\S]+?(?=#\>)
```

ScriptInfo comment:

```regex
\<#PSScriptInfo[\s\S]+?(?=#\>)
```

### SHA1 thumbprint validation

28be82b2378753a06b6e097714c0fa754248fa48

Parameter validation:

```regex
^[0-9a-f]{40}$
```

Match in string:

```regex
\b[0-9a-f]{40}\b
```

### GUID validation

For regex below all credits to [Regex for Guid][GUID regex]

```regex
[({]?(^([0-9A-Fa-f]{8}[-]?[0-9A-Fa-f]{4}[-]?[0-9A-Fa-f]{4}[-]?[0-9A-Fa-f]{4}[-]?[0-9A-Fa-f]{12})$)[})]?
```

[Table of Contents](#table-of-contents)

[multicursor]: https://code.visualstudio.com/docs/getstarted/tips-and-tricks#_multi-cursor-selection "Visit VSCode docs"
[msemail]: https://docs.microsoft.com/en-us/dotnet/standard/base-types/how-to-verify-that-strings-are-in-valid-email-format?redirectedfrom=MSDN "Visit Microsoft docs"
[stackemail]: https://stackoverflow.com/questions/5342375/regex-email-validation "Visit stackoverflow"
[ipv4 regex]: https://stackoverflow.com/questions/5284147/validating-ipv4-addresses-with-regexp "Visit stackoverflow"
[ipv6 regex]: https://stackoverflow.com/questions/53497/regular-expression-that-matches-valid-ipv6-addresses "Visit stackoverflow"
[GUID regex]: https://stackoverflow.com/a/35648213/12091999 "Visit stackoverflow"
