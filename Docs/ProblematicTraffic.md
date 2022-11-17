
# Problematic network traffic

List of dropped packets, blocked programs, how to troubleshoot well known issue and possible resolutions.

Note that all of these resolutions here are "forced",
meaning weakening the firewall just to fix the problem or to make firewall logs clean.

## Table of Contents

- [Problematic network traffic](#problematic-network-traffic)
  - [Table of Contents](#table-of-contents)
  - [Case 1: List of Windows services failing to connect outbound](#case-1-list-of-windows-services-failing-to-connect-outbound)
    - [Case 1: Troubleshooting](#case-1-troubleshooting)
    - [Case 1: Audit result](#case-1-audit-result)
  - [Case 2: List of dropped outbound packets during system boot](#case-2-list-of-dropped-outbound-packets-during-system-boot)
    - [Case 2: Troubleshooting](#case-2-troubleshooting)
    - [Case 2: Audit result](#case-2-audit-result)
  - [Case 3: Event log shows packet drops that are not logged into firewall log](#case-3-event-log-shows-packet-drops-that-are-not-logged-into-firewall-log)
    - [Case 3: Troubleshooting](#case-3-troubleshooting)
    - [Case 3: Audit result](#case-3-audit-result)
  - [Case 4: Updating Microsoft Office fails](#case-4-updating-microsoft-office-fails)
    - [Case 4: Troubleshooting](#case-4-troubleshooting)
    - [Case 4: Audit result](#case-4-audit-result)
  - [Case 5: Outbound protocol 0 port 0](#case-5-outbound-protocol-0-port-0)
    - [Case 5: Troubleshooting](#case-5-troubleshooting)
    - [Case 5 Audit result](#case-5-audit-result)
  - [Case 6: Dropped inbound UDP from LAN](#case-6-dropped-inbound-udp-from-lan)
    - [Case 6: Troubleshooting](#case-6-troubleshooting)
    - [Case 6: Audit result](#case-6-audit-result)
  - [Case 7: IPv6 loopback rule](#case-7-ipv6-loopback-rule)
    - [Case 7: Troubleshoot](#case-7-troubleshoot)
    - [Case 7: Audit result](#case-7-audit-result)
  - [Case 8: Connection dropped when specific network interface is assigned to rule](#case-8-connection-dropped-when-specific-network-interface-is-assigned-to-rule)
    - [Case 8: Troubleshooting](#case-8-troubleshooting)
    - [Case 8: Audit result](#case-8-audit-result)
  - [Case 9: Epic games UDP traffic to 230.0.0.1 is blocked](#case-9-epic-games-udp-traffic-to-230001-is-blocked)
  - [Case 10: Discovery and file and printer sharing issue on home networks (WORKGROUP)](#case-10-discovery-and-file-and-printer-sharing-issue-on-home-networks-workgroup)
    - [Case 10: Troubleshooting](#case-10-troubleshooting)
    - [Case 10: Audit result](#case-10-audit-result)

## Case 1: List of Windows services failing to connect outbound

This "case 1" can be easily reproduced by making a new user account and attempt to update store apps.

Program: `"%SystemRoot%\System32\svchost.exe"`

Cryptographic Services

- Service: `CryptSvc`
- Ports: 80, 443

Microsoft Account Sign-in Assistant

- Service: `wlidsvc`
- Ports: 443

Windows Update

- Service: `wuauserv`
- Ports: 443

Background Intelligent Transfer Service

- Service: `BITS`
- Ports: 80, 443

### Case 1: Troubleshooting

1. secpol.msc
2. Advanced Audit Policy Configuration
3. Advanced Audit Policies - Local Group Policy Object
4. Object Access
5. Audit Filtering Platform Packet drop (Audit failure)
6. Audit Filtering Platform Connection (Audit failure)
7. reproduce network traffic failure
8. Event log -> Windows logs -> Security
9. Note "Filter Run-Time ID" number
10. run: `netsh wfp show state`
11. Open xml file and CTRL + F noted filter id
12. take a look at "displayData" node to learn what rule caused the block
13. if value is "Default Outbound" it means no specific block rule, but,
firewall is set to block all outbound by default.
and that means our allow rule did not work. (Possible bug in WFP or lack of information)

[Reference for auditing][ref auditing]

### Case 1: Audit result

- Rules based on services automatically assign SID which is service SID,
and only those SID's are allowed network access.
- All services except those listed above, do not require additional account SID's such as logged in
user account SID, only their own SID.
- Rules for services listed above need current user account SID and few other SID's,
which is against the rule saying only service SID is allowed.
- To resolve the issue define one "extension" rule for services listed above with user accounts
which are allowed and needed to use those services.
- Note however, since Windows 10 you can't apply that rule to one or multiple services,
therefore a rule targets svchost and accounts, not service(s)
- That will make our firewall weaker, but it's the only way to allow those services trough firewall
if outbound traffic is blocked by default.
- The accounts needed depend from service to service, but we don't have much choice,
except adding all the accounts needed to separate rule as follows:

1. User account
2. `NT AUTHORITY\SYSTEM`
3. `NT AUTHORITY\LOCAL SERVICE`
4. `NT AUTHORITY\NETWORK SERVICE`

TODO: doesn't work for CryptSvc, see why

[Table of Contents](#table-of-contents)

## Case 2: List of dropped outbound packets during system boot

1. svchost.exe sending DNS request to configured DNS server (service unknown)
2. svchost.exe UDP multicast to 239.255.555.250 (service unknown)
3. svchost.exe UDP multicast to 224.0.0.252 (service unknown)
4. System IGMP (protocol 2) multicast to 224.0.0.22
5. System ICMPv6 multicast to ff02::16
6. System ICMPv6 multicast to ff02::1
7. svchost.exe UDP multicast ff02::fb 5353 5353 (service unknown)
8. svchost.exe UDP multicast ::1 ff02::c 57636 3702 (service unknown)
9. System ICMPv6 multicast to ff02::2

### Case 2: Troubleshooting

- Doing steps from Case 1 does not help much for svchost.exe since service is not shown in the report.
- In case of "System" Steps from Case 1 tell Default block was hit, meaning allow rule was ignored.

### Case 2: Audit result

- Boot time multicast dropped due to WFP Operation (Windows Filtering Platform).
- The transition from boot-time to persistent filters could be several seconds,
or even longer on a slow machine.
- During boot WFP (part of windows firewall) is set to block all, regardless of rules.
- what this means is, there is no other way but to ignore these drops,
there is nothing we can do about this.
- For all this to be true however, xml logs should tell that boot filter was hit,
but that's not the case.
- Additional investigation needed by allowing all ICMP and UDP explicitly.

[Reference for WFP Operation][ref wfp]

[Table of Contents](#table-of-contents)

## Case 3: Event log shows packet drops that are not logged into firewall log

1. Inbound from DNS servers source port 53 to random local port
2. Inbound from github source port 22 to random local port
3. Inbound TCP (protocol 6) source port 443 from akamai to random local port

### Case 3: Troubleshooting

- same as case 1

### Case 3: Audit result

1. set outbound DNS rule with LooseSourceMapping to true,
and firewall will know that these packets are related
and not unsolicited.
2. Additional investigation needed.
3. these packets are coming from Akamai CDN (content delivery network),
requested usually by internet browser,
such as google chrome, CDN ensures download of content from server most close to your location.

> My Firewall is reporting an "Unknown" Akamai Connection from port 443 of your server. Why?
>> When you connect to a site that is "Akamaized" with SSL content (Secure Sockets Layer),
your browser downloads an HTML file containing embedded URLs that tell your browser that some of
the objects necessary to finish displaying the page are located on Akamai servers. Next,
your browser contacts an Akamai server to obtain these images or streaming content.
Since the contact is made from port 443 of our server, this transaction is a legitimate HTTPS
connection. Generally a TCP service runs on a server on a well-known port number less than 1024;
in this case SSL service runs on port 443. A client connects with a random port number greater than
1023 that is assigned by the local operating system.

- Additional investigation needed for possible firewall rule resolution,
for now it's safer to ignore these than defining a rule that would possibly compromise system.

Unfortunately a link to this quote no longer exists.

[Table of Contents](#table-of-contents)

## Case 4: Updating Microsoft Office fails

- Either manually or automatic, updating office fails because outbound connection is blocked despite
correct allow rules

### Case 4: Troubleshooting

1. The failure is easy to observe with Process Monitor

- Clicktorun.exe starts downloading the most recent version of itself.
- After finishing the download Clicktorun.exe starts the downloaded version which then downloads
the new office version.
- The downloaded clicktorun wants to communicate with Microsoft servers directly completely
bypassing our rules.
- The downloaded clicktorun resides in folder whose name is random number of unknown meaning

[Reference for ClickToRun troubleshooting][issue clicktorun]

### Case 4: Audit result

**Update** This no longer seems to be problem since more recent version of Office suite

1. Impossible to define a rule which would monitor such behavior

- Resolution is to define a "temporary" rule which would be disabled by default, and enabled only
during update of office.
- Note that you can't specify program in this rule before starting download because the download
process creates a new random folder each time where it puts the executable,
so you end up in Cat and Mouse game.
- What we can do however is specify protocol, ports and users allowed, which is NT AUTHORITY\SYSTEM

[Table of Contents](#table-of-contents)

## Case 5: Outbound protocol 0 port 0

- TODO: Investigation needed.

### Case 5: Troubleshooting

- TODO: Investigation needed.

### Case 5 Audit result

- TODO: Investigation needed.

[Table of Contents](#table-of-contents)

## Case 6: Dropped inbound UDP from LAN

1. Firewall log may report inbound UDP drop, ie. from router to local 1900

### Case 6: Troubleshooting

1. Use process monitor to detect what processes/services sent/requested UDP connection

- adjust filter in process monitor to see if any UDP packets are received from same IP to same port.
- use TCP view or netstat to detect what service is listening on local 1900

### Case 6: Audit result

1. Packets are received just fine but small portion is dropped.

- TODO: additional investigation needed to figure out why.

[Table of Contents](#table-of-contents)

## Case 7: IPv6 loopback rule

1. IPv6 loopback packets dropped despite allow rule, Especially dropped during boot time.
2. unable to define loopback rule for IPv6
3. Defining a rule that would say allow all from ::1 or allow all to ::1 is not possible,
firewall will tell you ::1 (loopback address) is not valid or unspecified address.

### Case 7: Troubleshoot

- Define a rule that allows all possible traffic, but specify interface alias
(applicable to PowerShell only) for loopback to limit such traffic to loopback interface only
- Why firewall allows 127.0.0.1 but not ::1 is hard to tell, both are valid loopback addresses,
need to look for more information on MSDN

### Case 7: Audit result

- Making IPv6 loopback rule will not work, probably because both IPv4 and IPv6 loopback interfaces
have exactly the same alias.
- Solution is to set interface to "Any" for ICMPv6 and IPv6 multicast rules, that will work across
restarts, however shuting down system and turning back on will reproduce the problem regardless of rules.
- Another possible cause could be that some other hidden interface is generating this traffic.
- Additional investigation needed by allowing all packets explicitly.

[Table of Contents](#table-of-contents)

## Case 8: Connection dropped when specific network interface is assigned to rule

- In addition to interfaces shown in GPO which can be configured with InterfaceType parameter
there are some hidden network interfaces which need access to network, but not possible to
configure rules for these interfaces, except allowing all interfaces.

### Case 8: Troubleshooting

- It is absolute must to reboot system once for changes to be visible (sometimes twice to get log clear)
- Use `Get-NetadApter`, `Get-NetIPConfiguration` and `Get-NetIPInterface` to gather hidden adapter info
- Use `-InterfaceAlias` instead of `-InterfaceType` when defining firewall rule
- See [Command Help](CommandHelp.md) and [What is the Hyper-V Virtual Switch][hyperv switch]
for details.
- Module ComputerInfo now implements functions for this purpose, see also Test\Rule-InterfaceAlias.ps1
- See networking options in Hyper-V powershell module for additional troubleshooting
- Interfaces for different IP version share same interface alias, which could be the cause of failure
- Hyper-V virtual adapter/switch is reconfigured on every computer restart which could be the cause of
our rule being no longer valid.
- Adding explicit allow rules for troublesome traffic seems to resolve the problem, which
means it's worth spending time to invent the rules, ie:

1. Inbound UDP LocalPort 1900, 3702, 5353
2. Outbound UDP RemotePort 67, 68, 137, 547, 1900, 3702, 5353, 5355
3. Outbound IGMP

- Possible reason why rules won't work see: [LINK][issue rule interface]
- Another consideration is the type of Hyper-V virtual switch, see [LINK][issue rule interface2]

### Case 8: Audit result

- Even after creating sample test rules based on InterfaceAlias some packets are dropped, this
can happen for two reasons:

1. When you're on non public firewall profile, however virtual switch operates on public profile,
and it feels like private profile packets are dropped which is false.
2. When there is block rule for public traffic but you expect this not to be valid on your currently
active private profile firewall.

To check this is indeed so, separately log network traffic for each firewall profile!

- It's not possible to create rules based on adapters which are not configured for IP,
hidden, virtual or what ever doesn't matter, adapter must have IP address but doesn't have
to be connected to network.
- Regardless of host OS network profile virtual switch will operate on separate network profile,
most likely public profile, this means block rules for InterfaceType parameter will override
allow rules with InterfaceType Any.
- This traffic should be ignored if dropped due to block rules.
- Implementing rules for this traffic requires all network traffic to be bound to specific interface
alias, this includes **ALL** rules to make sure rules loaded with `InterfaceType` parameter don't
override those with `InterfaceAlias` parameter.

[Table of Contents](#table-of-contents)

## Case 9: Epic games UDP traffic to 230.0.0.1 is blocked

There is no need to troubleshoot this since Epic software uses addresses that are against IANA rules,
they have been notified about the problem which is present for already some time.

[Table of Contents](#table-of-contents)

## Case 10: Discovery and file and printer sharing issue on home networks (WORKGROUP)

If you disable "Rule merging" option (which is default) and make no use of predefined rules then:

- Other computers can't be discovered and this computer can't be discovered by other computers.
- Even setting explicit allow rules won't make it work
- No network packets are dropped at all to be able to troubleshoot firewall

In addition, a message saying "File and printer sharing is turned off".

### Case 10: Troubleshooting

One of the following should make the difference to confirm the issuse:

- Disable firewall
- Allow rule merging
- Apply "Network Discovery" predefined rules

Setting following GPO options explicitly makes no difference:

`Computer Configuration\Administrative Templates\Link-Layer Topology Discovery\`

- Turn on Mapper I/O (LLTDIO) driver
- Turn on Responder (RSPNDR) driver

Allowing default outbound, default inbound and no rules in place does not work.

Rule properties do not show any unusual properties, however some are undocumented, ex:

```powershell
Get-NetFirewallRule -PolicyStore PersistentStore -DisplayGroup "network discovery" `
-Direction Outbound -Enabled True | Get-NetFirewallPortFilter
```

"Incoming connections" troubleshooter tells us "security setting" is causing the issue

Setting our rules to be the same (or even more relaxing) as those predefined won't work.

### Case 10: Audit result

According to event logs it looks like there is some name resolution issue.

On another side there is some magic involved, Windows firewall requires at least 1 predefined rule
from "Network Discovery" and at least 1 predefined rule from "File and printer sharing" group.

These 2 rules don't have to be enabled, it's only important that the rule applies to current
network profile, this might get rid of the error message but will still not work.

It looks like Windows firewall loads some DLL's based on presence of at least one rule from group.

It turns out that Windows firewall does some magic based on `Group` parameter which isn't the same
thing as `DisplayGroup` which can't be even specified.

A solution is to get a built-in predefined group name and use it to create custom rules, for example:

```powershell
New-NetFirewallRule -DisplayName "Customized Predefined Rule" -Group "@FirewallAPI.dll,-32752" `
-PolicyStore ([Environment]::MachineName) -Direction
```

Create as many rules as needed to override predefined rules, alternatively import predefined rules
and modify as needed, for example:

```powershell
Get-NetFirewallRule -PolicyStore SystemDefaults -DisplayGroup "Network Discovery" `
-PolicyStoreSourceType Local | Copy-NetFirewallRule -NewPolicyStore ([Environment]::MachineName)
```

Status: Partially resolved

[Table of Contents](#table-of-contents)

[ref auditing]: https://docs.microsoft.com/en-us/windows/security/threat-protection/auditing/event-5157
[ref wfp]: https://docs.microsoft.com/en-us/windows/win32/fwp/basic-operation
[issue clicktorun]: https://www.reddit.com/r/sysadmin/comments/7hync7/updating_office_2016_hb_click_to_run_through
[hyperv switch]: https://www.altaro.com/hyper-v/the-hyper-v-virtual-switch-explained-part-1
[issue rule interface]: https://aidanfinn.com/?p=15222
[issue rule interface2]: https://www.nakivo.com/blog/hyper-v-networking-virtual-switches
[issue epic games]: https://forums.unrealengine.com/unreal-engine/feedback-for-epic/1800085-please-stop-violating-iana-rules
