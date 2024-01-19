
# Links and references

For anything that isn't covered by documentation in this repository you can perform additional\
research by using this collection of links for quick reference.

You might find these links relevant to extend repository code base and to develop firewall for
customized scenarios.

## Table of Contents

- [Links and references](#links-and-references)
  - [Table of Contents](#table-of-contents)
  - [Visual Studio Code](#visual-studio-code)
  - [PowerShell](#powershell)
  - [Module help and help files](#module-help-and-help-files)
  - [Git and GitHub](#git-and-github)
  - [IPv6](#ipv6)
  - [IPv4](#ipv4)
  - [IP general](#ip-general)
  - [Windows Firewall](#windows-firewall)
  - [Virtualization](#virtualization)
  - [OS and software](#os-and-software)
  - [Protocols](#protocols)
  - [Troubleshooting](#troubleshooting)
  - [WinRM and PowerShell remoting](#winrm-and-powershell-remoting)
  - [tools](#tools)
  - [Unclassified links](#unclassified-links)

## Visual Studio Code

- [VSCode documentation](https://code.visualstudio.com/docs)
- [Using VSCode for PowerShell Development](https://docs.microsoft.com/en-us/powershell/scripting/dev-cross-plat/vscode/using-vscode)
- [What is a workspace in Visual Studio Code](https://stackoverflow.com/questions/44629890/what-is-a-workspace-in-visual-studio-code)

[Table of Contents](#table-of-contents)

## PowerShell

- [PowerShell Core Reference](https://docs.microsoft.com/en-us/powershell/scripting/how-to-use-docs)
- [Windows PowerShell Reference](https://docs.microsoft.com/en-us/powershell/windows/get-started)

In the outline on the above 2 links search for modules that begin with "net*" such as:

1. netsecurity
2. nettcpip
3. netadapter
4. netnat

Also few commandlets from these modules:

1. Hyper-V
2. iscsi
3. iscsitarget

- [PowerShell Scripting Blog](https://devblogs.microsoft.com/scripting)
- [PowerShell Explained](https://powershellexplained.com)

[Table of Contents](#table-of-contents)

## Module help and help files

- [Supporting Online Help](https://docs.microsoft.com/en-us/powershell/scripting/developer/help/supporting-online-help)
- [Writing Help for PowerShell Modules](https://docs.microsoft.com/en-us/powershell/scripting/developer/help/writing-help-for-windows-powershell-modules)
- [About Comment-based Help](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help)
- [Examples of Comment-Based Help](https://docs.microsoft.com/en-us/powershell/scripting/developer/help/examples-of-comment-based-help)
- [Writing Help for PowerShell Cmdlets](https://docs.microsoft.com/en-us/powershell/scripting/developer/help/writing-help-for-windows-powershell-cmdlets)
- [How to Create a HelpInfo XML File](https://docs.microsoft.com/en-us/powershell/scripting/developer/help/how-to-create-a-helpinfo-xml-file)
- [How to Prepare Updatable Help CAB Files](https://docs.microsoft.com/en-us/powershell/scripting/developer/help/how-to-prepare-updatable-help-cab-files)

[Table of Contents](#table-of-contents)

## Git and GitHub

- [Git documentation](https://git-scm.com/doc)
- [GitHub Documentation](https://docs.github.com/en)

[Table of Contents](#table-of-contents)

## IPv6

- [IPv6 in Windows](https://support.microsoft.com/en-us/help/929852/guidance-for-configuring-ipv6-in-windows-for-advanced-users)
- [IPv6 address space](https://www.iana.org/assignments/ipv6-address-space/ipv6-address-space.xml)
- [IPv6 link-local address](https://www.cisco.com/c/en/us/support/docs/ip/ip-version-6-ipv6/113328-ipv6-lla.html)
- [ICMPv6](https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml)
- [IPv6 multicast](https://www.iana.org/assignments/multicast-addresses/multicast-addresses.xhtml)

[Table of Contents](#table-of-contents)

## IPv4

- [IPv4 multicast](https://www.iana.org/assignments/multicast-addresses/multicast-addresses.xhtml)
- [IPv4 address space](https://www.iana.org/assignments/ipv4-address-space/ipv4-address-space.xml)
- [IPv4 link-local address aka APIPA](https://wiki.wireshark.org/APIPA)
- [Limited broadcast](https://www.omnisecu.com/tcpip/what-is-limited-broadcast-in-ipv4.php)
- [Directed broadcast](https://www.kareemccie.com/2018/08/what-is-use-of-ip-directed-broadcast.html)

[Table of Contents](#table-of-contents)

## IP general

- [IP protocol numbers](https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml)
- [TCP/UDP port list](https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers)
- [Link-Local address](https://en.wikipedia.org/wiki/Link-local_address)
- [Network segmentation](https://www.omnisecu.com/cisco-certified-network-associate-ccna/benefits-of-segmenting-a-network-using-a-router.php)
- [Collision Domain and Broadcast Domain](https://www.omnisecu.com/cisco-certified-network-associate-ccna/what-are-collision-domain-and-broadcast-domain.php)

[Table of Contents](#table-of-contents)

## Windows Firewall

- [Windows Filtering Platform Architecture Overview](https://docs.microsoft.com/en-us/windows-hardware/drivers/network/windows-filtering-platform-architecture-overview)
- [WFP Operation](https://docs.microsoft.com/en-us/windows/win32/fwp/basic-operation)
- [Types of NAT](https://doc-kurento.readthedocs.io/en/6.9.0/knowledge/nat.html)
- [Windows Firewall](https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-firewall/windows-firewall-with-advanced-security)
- [Windows Filtering Platform](https://docs.microsoft.com/en-us/windows/win32/fwp/windows-filtering-platform-start-page)
- [WFP Monitoring](https://docs.microsoft.com/en-us/windows/win32/fwp/wfp-monitoring)
- [Windows Filtering Platform constants](https://docs.microsoft.com/en-us/windows-hardware/drivers/network/windows-filtering-platform-constants)
- [Understand TCP/IP addressing and subnetting basics](https://docs.microsoft.com/en-us/troubleshoot/windows-client/networking/tcpip-addressing-and-subnetting)
- [Firewall Rule Groups @FirewallAPI.dll](https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/networking-mpssvc-svc-firewallgroups)
- [Firewall Rules Needed for Common Transports](https://docs.microsoft.com/en-us/previous-versions/windows/desktop/ics/firewall-rules-needed-for-common-transports)
- [Windows Firewall Technologies](https://docs.microsoft.com/en-us/previous-versions/windows/desktop/ics/portal)
- [Firewall Rule and the Firewall Rule Grammar Rule](https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-gpfas/2efe0b76-7b4a-41ff-9050-1023f8196d16?redirectedfrom=MSDN)

[Table of Contents](#table-of-contents)

## Virtualization

- [What is the Hyper-V Virtual Switch and How Does it Work?](https://www.altaro.com/hyper-v/the-hyper-v-virtual-switch-explained-part-1/)
- [Windows Firewall On Hyper-V Host Has Nothing To Do With Virtual Machines](https://aidanfinn.com/?p=15222)
- [FW_RULE structure](https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-fasp/8c008258-166d-46d4-9090-f2ffaa01be4b)

[Table of Contents](#table-of-contents)

## OS and software

- [.NET Framework versions and dependencies](https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/versions-and-dependencies)
- [Windows 10 release information](https://docs.microsoft.com/en-us/windows/release-information)
- [Windows Server release information](https://docs.microsoft.com/en-us/windows-server/get-started/windows-server-release-info)
- [Security identifiers (SID)](https://docs.microsoft.com/en-us/windows/security/identity-protection/access-control/security-identifiers)
- [App capability declarations](https://docs.microsoft.com/en-us/windows/uwp/packaging/app-capability-declarations#device-capabilities)
- [How Visual Studio generates an app package manifest](https://docs.microsoft.com/en-us/uwp/schemas/appxpackage/uapmanifestschema/generate-package-manifest)

[Table of Contents](#table-of-contents)

## Protocols

- [Active FTP vs. Passive FTP](http://slacksite.com/other/ftp.html)
- [UNC Path](https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-dfsc/149a3039-98ce-491a-9268-2f5ddef08192)
- [NetBIOS over TCP/IP](https://docs.microsoft.com/en-us/previous-versions//bb727013(v=technet.10))

[Table of Contents](#table-of-contents)

## Troubleshooting

- [Advanced troubleshooting for TCP/IP issues](https://docs.microsoft.com/en-us/windows/client-management/troubleshoot-tcpip)
- [WFP Monitoring](https://docs.microsoft.com/en-us/windows/win32/fwp/wfp-monitoring)

[Table of Contents](#table-of-contents)

## WinRM and PowerShell remoting

- [Installation and configuration for Windows Remote Management](https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management)
- [about_WSMan_Provider](https://docs.microsoft.com/en-us/powershell/module/microsoft.wsman.management/about/about_wsman_provider)
- [Windows Remote Management Glossary](https://docs.microsoft.com/en-us/windows/win32/winrm/windows-remote-management-glossary)
- [How to configure WINRM for HTTPS](https://docs.microsoft.com/en-us/troubleshoot/windows-client/system-management-components/configure-winrm-for-https)
- [PowerShell Remoting over HTTPS with a self-signed SSL certificate](https://4sysops.com/archives/powershell-remoting-over-https-with-a-self-signed-ssl-certificate)
- [about_Remote_Requirements](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_remote_requirements)
- [about_Remote_Troubleshooting](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_remote_troubleshooting)
- [Enable-PSRemoting](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/enable-psremoting)

[Table of Contents](#table-of-contents)

## tools

- [makecab](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/makecab)
- [auditpol](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/auditpol)
- [gpupdate](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/gpupdate)
- [netsh](https://docs.microsoft.com/en-us/windows-server/networking/technologies/netsh/netsh-contexts)
- [netsh trace](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/jj129382(v=ws.11))
- [icacls](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/icacls)
- [takeown](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/takeown)
- [Windows Performance Analyzer](https://docs.microsoft.com/en-us/windows-hardware/test/wpt/windows-performance-analyzer)

[Table of Contents](#table-of-contents)

## Unclassified links

- [Check IP](https://whatismyipaddress.com/ip-lookup)
- [Check Domain](https://lookup.icann.org)
- [Command-line syntax key](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/command-line-syntax-key)
- [Windows PowerShell Cmdlets for Networking](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/jj717268(v=ws.11))
- [Windows .msc files overview](https://www.ghacks.net/2017/06/10/windows-msc-files-overview)
- [Create and Save a Custom Console by Using MMC](https://social.technet.microsoft.com/wiki/contents/articles/2046.create-and-save-a-custom-console-by-using-microsoft-management-console-mmc-using-the-msc-file-extension.aspx)

[Table of Contents](#table-of-contents)
