
# About this document

This document explains how to monitor Windows firewall activity and network activity on local system.\
*Note: all of these programs must be run as Administrator:*

## Monitor your firewall like a pro

As you may already know, Windows firewall does not give us any easy to use tools to monitor
what the firewall is doing.\
However there are few programs and techniques available to monitor firewall activity in live.

Note that there isn't an "All in one" solution, an ultimate program that does all the job.
instead we have to deal with multiple tools, each specialized for certain purpose,
if you're serious you will need them all.

Some tools are easy to use, some require learning how to use them, some have graphical interface
some are command line programs.\
Some tools do the same job as other tools that is they complement missing features of other programs,
but have other drawbacks.

For each program listed here you have a reference link (for tools built into Windows) and
download link (for external programs).

All of the tools listed here are signed by Microsoft, the only exception is mTail,
many people use it so it's easy to verify it's trusted, anyway you can verify it's behavior with
process monitor if you're suspicious.

## Process Monitor

- Process monitor will let you monitor process network activity, in addition of IP address and port
you will also know which process and which user (either system or human user) initiated connection,
and several other stuff which you can enable as needed in options.
- Process monitor is must have program, here is a screenshot while monitoring process network activity:\
click on image to enlarge!
![Alternate text](https://i.imgur.com/wNtDw8D.png)
- Inside the "Config" folder you will find process monitor configuration specialized for firewall
monitoring which you can import into your copy of process monitor.
- Note that configuration filters some network traffic which you may want to be able to see,
click on filter options to disable specific filters or add new ones.

- [Download process monitor](https://docs.microsoft.com/en-us/sysinternals/downloads/procmon)

## mTail

- mTail is another must have program, it will let you monitor firewall logs in real time.
- Here is a screenshot while monitoring the logs, click on image to enlarge:

![Alternate text](https://i.imgur.com/ljHcJss.png)

- Default mTail does not have special coloring, the colors you see in the screenshot are which
I made myself, you can grab this configuration from "Config" folder in this repository,
the config file is named `mtail_CC.ini`,
just place it next to mTail executable, restart mTail and open firewall log,
which is by default placed in *C:\Windows\System32\LogFiles\Firewall\pfirewall.log*\
However `SetupProfile.ps1` script will separate logs for each firewall profile.
- There is another config file called `mtail.ini` which needs to be (re)placed into:
`C:\Users\AdminAccountName\Roaming\mtail\`, this config file contains configuration to monitor
firewall activity for individual firewall profiles as well as number of personalized settings.
- Please keep in mind that settings configuration for mTail is highly buggy, and requires hacking
configuration files.

[Download mTail](http://ophilipp.free.fr/op_tail.htm)

## Event log

- Event viewer is built into Windows, it will tell you stuff that no other program can tell you!\
for example with this tool you can tell if somebody is intruding your firewall.
- Note that most of data you will see isn't available in firewall logs
(even if you enable "log ignored packets"), why is that so?
I don't know, maybe we should ask Microsoft, anyway, at least here is how to gain this hidden
firewall information.
- Here is sample screenshot, click on image to enlarge:

![Alternate text](https://i.imgur.com/8vo7aYD.png)

- To enable packet filter monitoring with event viewer you need to enable auditing option as follows:

1. click on start and type: `secpol.msc`
2. Advanced Audit Policy Configuration
3. Advanced Audit Policies - Local Group Policy Object
4. Object Access
5. Audit Filtering Platform Packet drop (Audit failure)
6. Audit Filtering Platform Connection (Audit failure) (this is optional,
I do not recommend enabling this to reduce amount of data,
and to focus on relevant, which is monitoring dropped packets)

[Event logging reference](https://docs.microsoft.com/en-us/windows/win32/eventlog/event-logging)

## WFP state and filter logs

Another powerful tool which will let you gather more information about specific firewall event.
click on image to enlarge:

![Alternate text](https://i.imgur.com/NMw1bpB.png)

![Alternate text](https://i.imgur.com/UF6an7e.png)

- WFP stand for "Windows Filtering Platform", a low level packet filter upon which Windows firewall
is built.
- you can access WFP logs, filter and state by executing following commands:\
```netsh wfp show state``` to show current state, such as detailed information about dropped or
allowed network packets.
```netsh wfp show filters``` to show current firewall filters
(filters are made of firewall rules btw,
rules by them self are just high level specifications translated into these low level filters.)
- when you execute show state, it will generate xml file in the same directory where you executed
the command, open this file with
your code editor such VS Code.
- what you are looking for here is an ID called "Filter Run-Time ID" and "Layer Run-Time ID",
you can obtain these ID's from event viewer as shown in Event log (screen shot above).
- select the "Filter Run-Time ID" number in event log
(Filtering platform packet drop event of your choice), press CTRL + C to copy, go to VS Code,
press CTRL + F to open "find box" and CTRL + V to paste the number,
and hit enter to jump to this event.
- here you are looking for "displayData" node which will tell what cause the drop,
this will be the name of a firewall rule or default firewall action such as default action or
boot time filter.
- There are other cool informations you can get out of this file, go ahead and experiment.
- NOTE: you need to enable at a minimum, auditing of dropped packet as explained in section
"Event log" above.

[WFP Reference](https://docs.microsoft.com/en-us/windows/win32/fwp/about-windows-filtering-platform)

## Windows Firewall

And of course we have Windows firewall it self in it's full glory.

- The firewall GUI will let you see and manage all your active rules in a user friendly way,
you can access either GPO firewall interface, (which is where this project loads the rules) or
open up firewall interface from control panel.
- the difference is that GPO firewall has precedence over the firewall in control panel,
(GPO store vs Persistent store, combined = Active Store)
- btw. Other documents in this repository will give you a reference and explain more about these
stores and what they are.
- another difference is that only in firewall from control panel you can see inbound and outbound
rules combined (aka. monitoring)
- Here is a screenshot on how to monitor the Active store, click on image to enlarge:

Monitoring: (control panel firewall, Active store)

![Alternate text](https://i.imgur.com/a97OEhS.png)

Management (Local group policy, GPO store)

![Alternate text](https://i.imgur.com/rB2vtsH.png)

[Windows Firewall reference](https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-firewall/windows-firewall-with-advanced-security)

## TCP View

TCP view is another tool that wil let you see what programs are listening on which ports on local system
![Alternate text](https://i.imgur.com/Joe7tMM.png)

[Download TCPView](https://docs.microsoft.com/en-us/sysinternals/downloads/tcpview)

## netstat

- Netstat is another tool built into Windows that does the same job as TCP view, but unlike TCP View
it will give you information that isn't available in TCP View, such as which service
is involved in connection.
- ie. useful to discover listening UDP related windows services or to show icmp statistics

![Alternate text](https://i.imgur.com/JSf5TZk.png)

[netstat reference](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/netstat)
