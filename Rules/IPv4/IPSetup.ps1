
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
# Variables related to IPv4
#

<# http://en.wikipedia.org/wiki/Private_network
NOTE: APIPA is how Microsoft refers to Link-Local
Address							CIDR				Subnet Mask			Designation
-------------					--------			-----------			-----------
10.0.0.0 - 10.255.255.255		10.0.0.0/8			255.0.0.0			Class A
172.16.0.0 - 172.31.255.255		172.16.0.0/12		255.240.0.0			Class B
192.168.0.0 - 192.168.255.255	192.168.0.0/16		255.255.0.0			Class C
255.255.255.255					---										Limited broadcast (Applies to All classes)
169.254.0.0-169.254.255.255		169.254.0.0/16		255.255.0.0			Automatic Private IP Addressing APIPA
#>

New-Variable -Name ClassA -Scope Local -Option Constant -Value 10.0.0.0/8
New-Variable -Name ClassB -Scope Local -Option Constant -Value 172.16.0.0/12
New-Variable -Name ClassC -Scope Local -Option Constant -Value 192.168.0.0/16

New-Variable -Name APIPA -Scope Local -Option Constant -Value 169.254.0.0/16

New-Variable -Name LimitedBroadcast -Scope Local -Option Constant -Value 255.255.255.255
