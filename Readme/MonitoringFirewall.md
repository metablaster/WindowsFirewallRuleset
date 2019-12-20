# About this document
This document explains how to monitor Windows firewall activity and network activity on local system.\
*Note: all of these programs must be run as Administrator:*

## Monitor your firewall like a pro
As you may already know, Windows firewall does not give us any easy to use tools to monitor what the firewall is doing.\
However there are few programs and techniques available to monitor firewall activity in live.\

**Process Monitor**
- Process monitor is must have program, here is a screenshot as I monitor process network activity right now:\
click on image to enlarge!
![](https://i.imgur.com/wNtDw8D.png)

- [Download process monitor](https://docs.microsoft.com/en-us/sysinternals/downloads/procmon)

**mTail**
- mTail is another must have program, it will let you monitor firewall logs in real time.
- Here is a screenshot as I monitor the logs right now, click on image to enlarge:
![](https://i.imgur.com/ljHcJss.png)

- Default mTail does not have speial coloring, the colors you see in the screenshot are which I made myself, you can grab\
this configuration from "Config" folder in this repository, just place it next to mTail executable, restart mTail and 
open firewall log, which is by default placed in *C:\Windows\System32\LogFiles\Firewall\pfirewall.log*

[Download mTail](http://ophilipp.free.fr/op_tail.htm)

**Event log**
- Event viewer is built into Windows, it will tell you stuff that no other program can tell you!\
for example with this tool you can tell if somebody is intruding your firewall
- Here is sample screenshot, click on image to enlarge:
![](https://i.imgur.com/8vo7aYD.png)

- To enable packet filter monitoring with event viewer you need to enable auditing option as follows:
1. click on start and type: `secpol.msc`
2. Advanced Audit Policy Configuration
3. Advanced Audit Policies - Local Group Policy Object
4. Object Access
5. Audit Filtering Platform Packet drop (Audit failure)
6. Audit Filtering Platfrom Connection (Audit failure) (this is optional, I do not recommend enabling this to reduce amount of data,
and to focus on relevant, which is monitoring dropped packets)



