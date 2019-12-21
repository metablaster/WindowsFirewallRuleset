
# Problematic network traffic

## Case 1: List of Windows services failing to connect outbound

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

**Case 1: Troubleshooting**
1. secpol.msc
2. Advanced Audit Policy Configuration
3. Advanced Audit Policies - Local Group Policy Object
4. Object Access
5. Audit Filtering Platform Packet drop (Audit failure)
6. Audit Filtering Platfrom Connection (Audit failure)
7. reproduce netwrok traffic failure
8. Event log -> Windows logs -> Security
9. Note "Filter Run-Time ID" number
10. run: `netsh wfp show state`
11. Open xml file and CTRL + F noted filter id
12. take a look at "displayData" node to learn what rule caused the block
13. if value is "Default Outbound" it means no specific block rule, but,
firewall is set to block all outbound by default.
and that means our allow rule did not work. (Possible bug in WFP or lack of information)

[Reference for auditing](https://docs.microsoft.com/en-us/windows/security/threat-protection/auditing/event-5157)

**Case 1: Audit result**
- Rules based on services automatically assign SID which is service SID, and only those SID's are allowed network access.
- All services except those listed above, do not require additional account SID's such as loged in user account SID, only their own SID.
- Rules for services listed above need current user account SID and few other SID's, which is against the rule saying only service SID is allowed.
- To resolve the issue define one "extension" rule for services listed above with user accounts which are allowed and needed to use those services.
- Note however, since Windows 10 you can't apply that rule to one or multiple services, therefore a rule targets svchost and accounts, not service(s)
- That will make our firewall weaker, but it's the only way to allow those services trough firewall if outbound traffic is blocked by default.
- The accounts needed depend from service to service, but we don't have much choice, except adding all the accounts needed to separate rule as follows:
1. User account
2. NT AUTHORITY\SYSTEM
3. NT AUTHORITY\LOCAL SERVICE
4. NT AUTHORITY\NETWORK SERVICE

## Case 2: List of dropped outbound packets during system boot
1. svchost.exe sending DNS request to configure DNS server (service unknown)
2. svchost.exe UDP multicast to 239.255.555.250 (service unknown)
3. svchost.exe UDP multicast to 224.0.0.252 (service unknown)
4. System IGMP (protocol 2) multicast to 224.0.0.22
5. System ICMPv6 multicast to ff02::16
6. System ICMPv6 multicast to ff02::1
7. svchost.exe UDP multicast ff02::fb 5353 5353 (service unknown)
8. svchost.exe UDP multicast ::1 ff02::c 57636 3702 (service unknown)
9. System ICMPv6 multicast to ff02::2

**Case 2: Troubleshooting**
- Doing steps from Case 1 does not help much for svchost.exe since service is not shown in the report.
- In case of "System" Steps from Case 1 tell Default block was hit, meaning allow rule was ignored.

**Case 2: Audit result**
- Boot time multicast dropped due to WFP Operation (Windows Filtering Platform).
- The transition from boot-time to persistent filters could be several seconds, or even longer on a slow machine.
- During boot WFP (part of windows firewall) is set to block all, regardless of rules.
- what this means is, there is no other way but to ignore these drops, there is nothing we can do about this.
- Additional investigation needed by allowing all explicitly.

[Reference for WFP Operation](https://docs.microsoft.com/en-us/windows/win32/fwp/basic-operation)

## Case 3: Event log shows inbound packet drops, firewall log does not show these drops
1. Inbound from DNS server source port 53 to random local port
2. Inbound from github source port 22 to random local port
3. Inbound TCP (protocol 6) source port 443 to random local port

**Case 3: Troubleshooting**
- TODO: input missing

**Case 3: Audit result**
1. set outbound DNS rule with LooseSourceMapping to true, and firewall will know that these packets are related
and not unsolicited.
2. Additional investigation needed.
3. these packets are comming from Akamai CDN (content delivery network), requested usually by internet browser,
such as google chrome, CDN ensures download of content from server most close to your location.
> My Firewall is reporting an "Unknown" Akamai Connection from port 443 of your server. Why?
>> When you connect to a site that is "Akamaized" with SSL content (Secure Sockets Layer), your browser downloads an HTML file containing embedded URLs that tell your browser that some of the objects necessary to finish displaying the page are located on Akamai servers. Next, your browser contacts an Akamai server to obtain these images or streaming content. Since the contact is made from port 443 of our server, this transaction is a legitimate HTTPS connection. Generally a TCP service runs on a server on a well-known port number less than 1024; in this case SSL service runs on port 443. A client connects with a random port number greater than 1023 that is assigned by the local operating system.
- Additinoal investigation needed for possible firewall rule resolution, for now it's safer to ignore these than defining a rule that would possibly compromize our system.

[Reference for akamai](https://www.akamai.com/us/en/support/end-user-faq.jsp)

## Case 4: Updating Microsoft Office fails
1. either manually or automatic, updating office fails because outbound connection is blocked despite correct allow rules

**Case 4: Troubleshooting**
1. The failure is easy to observe with Process Monitor
- Clicktorun.exe starts downloading the most recent version of itself.
- After finishing the download Clicktorun.exe starts the downloaded version which then downloads the new office version.
- The downloaded clicktorun wants to communicate with Microsoft servers directly completely bypassing our rules.
- The downloaded clicktorun resides in folder whose name is random number of unknown meaning

[Reference for ClickToRun](https://www.reddit.com/r/sysadmin/comments/7hync7/updating_office_2016_hb_click_to_run_through)

**Case 4: Audit result**
1. Impossible to define a rule which would monitor behavior of such stupidly designed programs.
- Resolution is to define a "temporary" rule which would be disabled by default, and enabled only during update of office.
- Note that you can't specify program in this rule before starting download because the download process creates a new random folder each time where it puts the executable, so you end up in Cat and Mouse game.
- What we can do however is specify protocol, ports and users allowed, which is NT AUTHORITY\SYSTEM

## Case 5: Outbound protocol 0 port 0
- TODO: Investigation needed.

## Case 6: Dropped inbound UDP from LAN
1. Firewall log may report inbound UDP drop, ie. from router to local 1900

**Case 6: Troubleshooting**
1. Use process monitor to detect what processs/service sent/requested UDP connection
- adjust filter in process monitor to see if any UDP packets are received from same IP to same port.
- use TCP view or netstat to detect what service is listening on local 1900

**Audit result**
1. Packets are received just fine but small portion is dropped.
- additional investigation needed to figure out why.
