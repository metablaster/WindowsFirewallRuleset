
# About this document

There are many ways to get stuck with networking, other documentation mostly focuses on how to
work with or troubleshoot firewall, but here the aim is to make troubleshooting other network
related problems more easy.

This are the most basic troubleshooting procedures one should always perform when stuck.

## Open up PowerShell

Press `Windows key + X` then click on Windows PowerShell (Admin)

## First clear DNS cache to isolate that problem

```powershell
ipconfig /flushdns
```

## Perform DNS query

Perform multiple DNS queries and make sure they are successful.\
Feel free to test more hosts/IP addresses as needed for your case.

```powershell
Resolve-DnsName 8.8.8.8
Resolve-DnsName microsoft.com
```

## Take a look at your network information

These commands will save output to file, you can review those files so that you don't need
to run the commands multiple times, or to be able to share output in some computer forums so that
somebody can help you out.

```powershell
ipconfig /all > $home\Desktop\ipconfig.txt
Get-NetAdapter | ? HardwareInterface | select * > $home\Desktop\adapter.txt
```

## Ping hosts

Pinging hosts is important to isolate specific routes/sites:

```powershell
ping 8.8.8.8 > $home\Desktop\ping.txt
ping google.com >> $home\Desktop\ping.txt
```

`ipconfig /all` command (above) will telly you IP address of your router, you should definitely
ping it, here is example entry from `ipconfig /all`

Default Gateway . . . . . . . . . : 192.168.8.1

Now see if route to router is working by pinging address from your output:

```powershell
ping 192.168.8.1 >> $home\Desktop\ping.txt
```

You may also want to ping other computer on your local network, to find out their IP, login to
computer in question and run `ipconfig /all` on that computer, then look at field that say:

`IPv4 Address. . . . . . . . . . . :`

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

`Settings > Network & Internet > Status > Network Reset`

## Check for updates

Make sure your system and drivers are fully up to date:

* See below link on how to update system:
https://support.microsoft.com/en-us/help/4027667/windows-10-update

It's good to continue checking for updates after they are installed, until there is no new updates,
it's not bad to reboot system after update even if not asked to do so.

* To update drivers make sure you download them from either Microsoft or official manufacturer for
your hardware.

Never user driver updater tools or similar automated solutions.
Never download drivers from sites of questionable reputation or those who claim to have up to date
drivers but are not original hardware vendors.

Do it manually in this order:

1. chipset driver
2. reboot system
3. the rest of drivers
4. reboot system

## Troubleshoot WI-FI

Below link explains how to troubleshoot WI-FI problems, some of the steps are already covered here:

https://support.microsoft.com/en-us/help/10741/windows-fix-network-connection-issues

## Trace route to random hosts on internet

Traceroute will help you figure out which node on the network isn't responding.

Usually that means either site problem, ISP problem or router problem.\
It depends at which node you get failure.

```powershell
Test-NetConnection google.com -traceroute
Test-NetConnection microsoft.com -traceroute
```

## Disable firewall

If nothing so far worked disable firewall and try all over again.\
If things start to work it's likely misconfigured firewall.

See below link on how to disable both GPO and Control Panel firewall:
https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Readme/DisableFirewall.md

**NOTE:** If you experience this problem only while having firewall enabled from this project,
feel free to open new issue and provide as much details (results) as possible from this document.

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

## Change DNS server

google DNS servers are fast and reliable, see below link to change your DNS settings to use
google DNS:

https://developers.google.com/speed/public-dns/docs/using

## Restart or reset router

Usually some routers if not restarted often will stuck and cause slow internet or loss of network
completely.

Restart your router, and if that doesn't work you can also try reset it to factory defaults.
Resetting to factory defaults is done by pushing a toothpick or something like that into a tinny
hole in the router.

This will reset router and WI-FI password and the default one can be found on the sticker somewhere
on the router.

## Check your LAN connection

Check your LAN cable, verify it is properly connected and functioning.

## Contact your ISP

If other computers are not working on your LAN, or if you have no other computers to test with,
call your ISP and ask them what's the problem.

## Perform speed test

Visit below link to perform network speed test:

https://www.speedtest.net

Try different servers to see if there is a difference

## Try another adapter

If you got to this point you should really try out another adapter, but before doing so, make sure
to verify other devices on your network work properly (ex. no internet issues)

Which means something is wrong with your operating system or adapter.

You may want to boot linux live ISO to make sure your adapter or operating system is not faulty.

## Reinstall Windows

This is last resort, if operating system is bad reinstall it:

https://www.microsoft.com/en-us/software-download/windows10

## If nothing so far worked

Try search for help on computer forums, there are many experts out there,
or visit computer shop and let them fix your issue.
