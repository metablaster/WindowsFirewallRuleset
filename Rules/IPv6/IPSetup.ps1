
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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

. $PSScriptRoot\..\DefaultParameters.ps1

#
# Variables related to IPv6
#

<# https://www.iana.org/assignments/ipv6-address-space/ipv6-address-space.xhtml
0000::/8	Reserved by IETF
0100::/8	Reserved by IETF
0200::/7	Reserved by IETF
0400::/6	Reserved by IETF
0800::/5	Reserved by IETF
1000::/4	Reserved by IETF

The IPv6 Unicast space encompasses the entire IPv6 address range with the exception of ff00::/8, per [RFC4291]
IANA unicast address assignments are currently limited to the IPv6 unicast address range of 2000::/3.
2000::/3	Global Unicast

4000::/3	Reserved by IETF
6000::/3	Reserved by IETF
8000::/3	Reserved by IETF
a000::/3	Reserved by IETF
c000::/3	Reserved by IETF
e000::/4	Reserved by IETF
f000::/5	Reserved by IETF
f800::/6	Reserved by IETF
fc00::/7	Unique Local Unicast	For complete registration details, see [IANA registry iana-ipv6-special-registry]
fe00::/9	Reserved by IETF
fe80::/10	Link-Scoped Unicast		Reserved by protocol.
fec0::/10	Reserved by IETF		Deprecated in September 2004. Formerly a Site-Local scoped address prefix.
ff00::/8	Multicast
#>

New-Variable -Name GlobalUnicast -Scope Local -Option Constant -Value 2000::/3
New-Variable -Name UniqueLocalUnicast -Scope Local -Option Constant -Value fc00::/7
New-Variable -Name LinkScopedUnicast -Scope Local -Option Constant -Value fe80::/10
New-Variable -Name Multicast -Scope Local -Option Constant -Value ff00::/8
