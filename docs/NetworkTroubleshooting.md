
# Network troubleshooting detailed guide

There are many ways to get stuck with networking, other documentation in this project mostly focuses
on how to work with or troubleshoot firewall, but here the aim is to make troubleshooting other
network related problems in detail.

It covers wide area of network problems and is based on [Process of elimination][process elimination]
meaning you go step by step and isolating each area making it less probable to be the cause of an issue.

This are the most basic troubleshooting procedures one should always perform when facing network issues.

## Table of Contents

- [Network troubleshooting detailed guide](#network-troubleshooting-detailed-guide)
  - [Table of Contents](#table-of-contents)
  - [Open up PowerShell](#open-up-powershell)
  - [First clear DNS cache to isolate that problem](#first-clear-dns-cache-to-isolate-that-problem)
  - [Perform DNS query](#perform-dns-query)
  - [Take a look at your network information](#take-a-look-at-your-network-information)
  - [Ping hosts](#ping-hosts)
  - [Reset network](#reset-network)
  - [Check for updates](#check-for-updates)
  - [Troubleshoot WI-FI](#troubleshoot-wi-fi)
  - [Trace route to random hosts on the internet](#trace-route-to-random-hosts-on-the-internet)
  - [Disable firewall](#disable-firewall)
  - [Disable and enable network adapter](#disable-and-enable-network-adapter)
  - [Change DNS server](#change-dns-server)
  - [Restart or reset router](#restart-or-reset-router)
  - [Check your LAN connection](#check-your-lan-connection)
  - [Contact your ISP](#contact-your-isp)
  - [Perform internet speed test](#perform-internet-speed-test)
  - [Perform LAN speed test](#perform-lan-speed-test)
  - [Try another adapter](#try-another-adapter)
  - [Change adapter properties](#change-adapter-properties)
  - [Configure your router](#configure-your-router)
  - [I have game multiplayer issues](#i-have-game-multiplayer-issues)
  - [Issues with LAN, Workgroup, Home group, Remote desktop or sharing](#issues-with-lan-workgroup-home-group-remote-desktop-or-sharing)
  - [Reset firewall](#reset-firewall)
  - [Run network troubleshooter](#run-network-troubleshooter)
  - [Look at IP route information](#look-at-ip-route-information)
  - [Look at your hosts file](#look-at-your-hosts-file)
  - [Firewall issue](#firewall-issue)
  - [Check for Windows Auto-Tuning](#check-for-windows-auto-tuning)
  - [Specific problems](#specific-problems)
  - [Troubleshoot or reinstall Windows](#troubleshoot-or-reinstall-windows)
  - [If nothing works](#if-nothing-works)

## Open up PowerShell

Press `Windows key + X` then click on "Windows PowerShell (Admin)"

[Table of Contents](#table-of-contents)

## First clear DNS cache to isolate that problem

```powershell
Clear-DnsClientCache
```

[Table of Contents](#table-of-contents)

## Perform DNS query

Perform multiple DNS queries and make sure they are successful.\
Feel free to test more hosts/IP addresses as needed for your case.

```powershell
Resolve-DnsName 8.8.8.8
Resolve-DnsName microsoft.com
```

[Table of Contents](#table-of-contents)

## Take a look at your network information

These commands will save output to file, you can review those files so that you don't need
to run the commands multiple times, or to be able to share output in some computer forums so that
somebody can help you out.

```powershell
ipconfig /all > $env:SystemDrive\ipconfig.txt
Get-NetAdapter | ? HardwareInterface | select * > $env:SystemDrive\adapter.txt
```

[Table of Contents](#table-of-contents)

## Ping hosts

Pinging hosts is important to isolate specific routes/sites:

```powershell
ping 8.8.8.8 > $env:SystemDrive\ping.txt
ping google.com >> $env:SystemDrive\ping.txt
```

`ipconfig /all` command (above) will telly you IP address of your router,\
you should definitely ping it, here is example entry from `ipconfig /all`

Default Gateway . . . . . . . . . : 192.168.4.1

Now see if route to router is working by pinging address from your output:

```powershell
ping 192.168.8.1 >> $env:SystemDrive\ping.txt
```

You might also want to ping other computers on your local network, to find out their IP,\
login to computer in question and run `ipconfig /all` on that computer, then look for
address at field that say:

`IPv4 Address. . . . . . . . . . . :`

[Table of Contents](#table-of-contents)

## Reset network

Type following commands into console to reset network

```powershell
ipconfig /flushdns
ipconfig /release
ipconfig /renew
netsh winsock reset
netsh int ip reset
ipconfig /release
ipconfig /renew
```

At this point reboot system and do all of the previous steps all over again to verify if that
worked or to see if something new come out.

Remember, you can't make mistake of rebooting system too much, more reboots is better while
troubleshooting, even if not needed.

Alternative way to reset network is by using "Settings" app in Windows 10 as follows:

`Settings > Network & Internet > Status > Network Reset`\
It's important to let network reset finish without interruption.

[Table of Contents](#table-of-contents)

## Check for updates

Make sure your system and drivers are fully up to date:

- See link below on how to update system:
[Update Windows 10][update windows]

It's good to continue checking for updates after they are installed, until there is no new updates,
it's not bad to reboot system after update even if not asked to do so.

- To update drivers make sure you download them from either Microsoft or official manufacturer for
your hardware.

Never user driver updater tools or similar automated solutions.
Never download drivers from sites of questionable reputation or those who claim to have up to date
drivers but are not original hardware vendors.

Do it manually in this order:

1. chipset driver
2. reboot system
3. the rest of drivers
4. reboot system

[Table of Contents](#table-of-contents)

## Troubleshoot WI-FI

Link below explains how to troubleshoot WI-FI problems, some of the steps are already covered here:

[Fix WI-FI issues][fix wifi]

[Table of Contents](#table-of-contents)

## Trace route to random hosts on the internet

Traceroute will help you figure out which node on the network isn't responding.

Usually that means either site problem, ISP problem or router problem.\
It depends at which node you get failure.

```powershell
Test-NetConnection google.com -traceroute
Test-NetConnection microsoft.com -traceroute
```

Alternative way to run trace route is:

```powershell
tracert google.com
tracert microsoft.com
```

**NOTE:** Some sites (such as microsoft) drop ICMP packets, so make sure to test multiple sites.

[Table of Contents](#table-of-contents)

## Disable firewall

If nothing so far worked disable firewall and try all over again.\
If things start to work it's likely misconfigured firewall.

See link below on how to disable both GPO and Control Panel firewall:\
[Disable Firewall](DisableFirewall.md)

**NOTE:** If you experience this problem only while having firewall enabled from this project,
feel free to open new issue and provide as much details (results) as possible from this document.

[Table of Contents](#table-of-contents)

## Disable and enable network adapter

Disabling and enabling adapters can help, replace "Adapter Name" with actual adapter name.

```powershell
Disable-NetAdapter -Name "Adapter Name"
Enable-NetAdapter -Name "Adapter Name"
```

To learn which is your adapter for above commands look at your `adapter.txt` from earlier step
or run:

```powershell
Get-NetAdapter
```

Alternative way to disable/enable adapter is in control panel at:

`Control Panel\All Control Panel Items\Network and Sharing Center`\
Click on `Change Adapter Settings`, right click your adapter that is having problem,
then disable and enable back.

[Table of Contents](#table-of-contents)

## Change DNS server

google DNS servers are fast and reliable, see link below to change your DNS settings to use google DNS:

[google DNS servers][google dns]

[Table of Contents](#table-of-contents)

## Restart or reset router

Usually some routers if not restarted often will stuck and cause slow internet or loss of network
completely.

Restart your router, and if that doesn't work you can also try reset it to factory defaults.\
Resetting to factory defaults is done by pushing a toothpick or something like that into a tinny
hole in the router.

This will reset router and WI-FI password and the default one can be found on the sticker somewhere
on the router.

[Table of Contents](#table-of-contents)

## Check your LAN connection

Check your LAN cable, verify it is properly connected and functioning.

[Table of Contents](#table-of-contents)

## Contact your ISP

If other computers are not working on your LAN, or if you have no other computers to test with,
call your ISP and ask them what's the problem.

[Table of Contents](#table-of-contents)

## Perform internet speed test

If you're having problem with slow connection, visit link below to perform network speed test:

[Internet speed test][speedtest]

Try different servers to see if there is a difference, you might need to contact your ISP and
ask them how much it will cost to get faster internet. (more pay = faster)

See if your ISP can install you optic cable into your house, and for what price.

[Table of Contents](#table-of-contents)

## Perform LAN speed test

If your network speed is slow and related only to local network (ex. between computers behind router),
you can test LAN speed with tool called NetIO:

[NetIO-GUI][netio]

[Table of Contents](#table-of-contents)

## Try another adapter

If you got to this point you should really try out another network adapter, but before doing so,
make sure to verify other devices on your network work properly (ex. no internet issues)

Which means something is wrong with your operating system or adapter.

You might want to boot linux live ISO to make sure your adapter or operating system is not faulty.

[Table of Contents](#table-of-contents)

## Change adapter properties

There are many different network adapters, most of them have settings which you can access via
device manager.

Make sure to open device manager as Administrator:\
[Open device manager][device manager]

Open your adapter properties and you'll find settings somewhere under "Advanced" tab or something
like that.
Depending on your adapter, here are links that help explain the meaning of adapter settings options:

**NOTE:** This settings are universal, not always limited to specific hardware vendor:

- [Advanced Intel Wireless Adapter Settings][adapter wifi settings]
- [Advanced Network Adapter Driver Settings][adapter eth settings]
- [Resolving Issues with Energy Efficient Ethernet (EEE) or Green Ethernet][adapter eee issues]
- [Optimal setting for advanced parameters for Realtek PCI-e GBE family network card][adapter realtek settings]

[Table of Contents](#table-of-contents)

## Configure your router

Read documentation about yor router, learn what different options do and adjust your router
setting for optimal performance.

Restarting router is recommended to check if new configuration makes any difference.

[Table of Contents](#table-of-contents)

## I have game multiplayer issues

If your problem is MMO gaming (online multiplayer), LAN multiplayer, [Hotseat][hotseat]
and similar then you must make sure your router NAT settings are properly configured.

Log in to your router and find "NAT" settings, possible options are:

- Full Cone NAT (Static NAT)
- Restricted Cone NAT (Dynamic NAT)
- Port Restricted Cone NAT (Dynamic NAT)
- Symmetric NAT (Dynamic NAT)

For gaming your want "Full Cone NAT (Static NAT)"\
remember, "Symmetric NAT (Dynamic NAT)" may cause you a lot of multiplayer troubles.

[Table of Contents](#table-of-contents)

## Issues with LAN, Workgroup, Home group, Remote desktop or sharing

Link below contains detailed guidelines:

[LAN Setup](LAN%20Setup)

[Table of Contents](#table-of-contents)

## Reset firewall

Link Below explains how to reset both GPO firewall and firewall in control panel:

[Reset Firewall](ResetFirewall.md)

[Table of Contents](#table-of-contents)

## Run network troubleshooter

Usually network troubleshooter in Windows should be able to resolve the problem, or at least
tell you what is going on:

1. On Windows 10 press `Windows key + I` to open settings app
2. type into search box `troubleshoot` and select `troubleshoot settings`
3. click on `additional troubleshooters`
4. here you'll find several network troubleshooters, run them all.
5. If problem is not fixed right away you might need to reboot system

On another systems, alternative way is:

1. Open control panel and click on "Network and sharing center"
2. Click on "Troubleshoot problems"
3. depending on your system choose different options to troubleshoot problems.
4. what you are looking for is "Network reset" and "Diagnose problems"
5. If problem is not fixed right away you might need to reboot system

[Table of Contents](#table-of-contents)

## Look at IP route information

```powershell
Get-NetRoute
```

For more information about see [Get-NetRoute][ref netroute]

For more information about routing table [routing table][wikipedia routing table]

[Table of Contents](#table-of-contents)

## Look at your hosts file

You want to make sure your younger brother or sister doesn't have fun with you!

Visit this folder: `C:\Windows\System32\drivers\etc`

Open `hosts` file with notepad or some other text editor and make sure all lines begin with hash "#"\
If any lines doesn't begin with hash, then either add hash to those lines or delete entry.

[Table of Contents](#table-of-contents)

## Firewall issue

To troubleshoot firewall take a look at:

- [Monitoring Firewall](MonitoringFirewall.md)
- [Problematic Traffic](ProblematicTraffic.md)
- [Rest of documentation](/Docs)

[Table of Contents](#table-of-contents)

## Check for Windows Auto-Tuning

Windows Auto-Tuning was designed to automatically improve the performance for programs that receive
TCP data over a network.

To see current setting run:

```powershell
netsh interface tcp show global
```

Windows Auto-Tuning should be enabled and left alone unless you have a router, WI-Fi, network card,
or a firewall that does not support this feature.

To disable setting run:

```powershell
netsh int tcp set global autotuninglevel=disabled
```

To enable setting run:

```powershell
netsh int tcp set global autotuninglevel=normal
```

[Table of Contents](#table-of-contents)

## Specific problems

Few external references for specific issues:

[Computer Name Won't Resolve on Network][name resolution issue]

[Table of Contents](#table-of-contents)

## Troubleshoot or reinstall Windows

First see recovery options in Windows 10, you might be able to recover your system to previous good state.

[Recovery options in Windows 10][recover windows]

reinstalling is is last resort, if operating system is bad reinstall it:

[Download Windows 10][download windows]

[Table of Contents](#table-of-contents)

## If nothing works

Try search for help on computer forums, there are many experts out there,
or visit computer shop and let them fix your issue.

To get good support in forums make sure you provide as much details as you can, this includes:

1. Your network information by sharing outputs from commands discussed so far here
2. Your operating system version, detailed hardware and driver info
3. hardware information on your network such as routers, modems, cables etc.
4. Description of things you did prior to your problem.
5. Make it short and to the point, nobody likes to read long posts!

[Table of Contents](#table-of-contents)

[update windows]: https://support.microsoft.com/en-us/help/4027667/windows-10-update
[fix wifi]: https://support.microsoft.com/en-us/help/10741/windows-fix-network-connection-issues
[process elimination]: https://en.wikipedia.org/wiki/Process_of_elimination
[google dns]: https://developers.google.com/speed/public-dns/docs/using
[speedtest]: https://www.speedtest.net
[netio]: https://sourceforge.net/projects/netiogui
[device manager]: https://support.microsoft.com/en-us/help/4026149/windows-open-device-manager
[adapter wifi settings]: https://www.intel.com/content/www/us/en/support/articles/000005585/network-and-i-o/wireless.html
[adapter eth settings]: http://techgenix.com/advanced-network-adapter-driver-settings
[adapter eee issues]: https://www.dell.com/support/kbdoc/en-us/000134483/resolving-issues-with-energy-efficient-ethernet-eee-or-green-ethernet?lwp=rt
[adapter realtek settings]: https://superuser.com/questions/853500/optimal-setting-for-advanced-parameters-for-realtek-pci-e-gbe-family-network-car
[hotseat]: https://en.wikipedia.org/wiki/Hotseat_(multiplayer_mode) "wikipedia hotseat"
[ref netroute]: https://docs.microsoft.com/en-us/powershell/module/nettcpip/get-netroute?view=win10-ps
[wikipedia routing table]: https://en.wikipedia.org/wiki/Routing_table
[name resolution issue]: https://www.infopackets.com/news/10369/how-fix-computer-name-wont-resolve-network-april-update
[recover windows]: https://support.microsoft.com/en-us/help/12415/windows-10-recovery-options
[download windows]: https://www.microsoft.com/en-us/software-download/windows10
