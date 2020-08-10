# About this document

Here are the most common problems running powershell scripts in this project and how to resolve them.
Also general questions and answers regarding firewall.

## I applied the rule(s) but it doesn't work, program xyz.exe doesn't connect to internet

1. Close down the program which is unable to connect to network completely
2. In GPO select each rule that applies to this program, right click and disable,
   then enable again.
3. Open program in question and try again, in most cases this should work.
4. If not try rebooting system, Windows firewall sometimes just doesn't instantly respect the rules.
5. If still no luck, open rule properties in GPO and under advanced tab allow all interface types,
all users or both, however allowing all interfaces or users should be only a temporary measure.

INFO: In addition to interfaces shown in GPO there are some hidden network interfaces,
until I figure out how to make rules based on those allow them all if this resolves the problem.\
To troubleshoot hidden adapters see [ProblematicTraffic.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Readme/ProblematicTraffic.md)

## I got an error "Network path not found"

Please make sure you have at a minimum following network services set to automatic and
make sure they are running:

1. Workstation (LanmanWorkstation)
2. Server (LanmanServer)
3. TCP/IP NetBIOS Helper service (lmhosts)

## There is no output, the script hangs and stays blank until "Enter" is pressed

This is for sure a bug, the script is waiting for input but it's not known for what exactly,
a lot of these have been fixed already, please report them if possible!

## Does this firewall give me the right protection?

Good firewall setup is essential for computer security, and, if not misused then the answer is yes
but only for the firewall (network) part of protection.

For maximum security you need much more than just good firewall, here is a minimum list:

1. Using non Administrative Windows account for almost all use, if you already are Administrator then
your system can no longer be trusted even if you're expert. (anyway,
experts don't use Administrator accounts)

2. Installing and running only digitally signed software, and only those publishers you trust,
if you really need to install warez and similar then it's already game over (uninstalling won't help).

3. Visiting only trusted web sites, and double checking any web link before clicking on it,
If you really need to visit odd sites and freely click around, then please do it in virtual machine
(isolated browsing is OK too)

4. If you don't use password manager with virtual keyboard only, then your accounts and passwords
are not safe.

As you can see, no mention of anti-virus, anti-spyware, firewall, VPN or any kind of similar
"security software", because, if you strictly follow these 4 rules then most likely you don't need
anything else.

If you don't follow these rules, no firewall, anti virus or security expert is going to help much,
the real purpose of firewall or anti virus is to protect yourself from the following:

1. You made a mistake of accidentally breaking one of these 4 rules (your fault)

2. You are target of hackers. (not your fault)

In any case if any of the above 4 rules are broken, your system is not safe and usually that means
it can not be trusted, only hard drive reformat and clean system reinstall can return trust.

By not trusted it means, not trusted for:

1. online payments, cash transfer, online banking etc.

2. private data storage, personal data safety etc.

3. your anonymity and protection from identity theft.

4. safety of your online accounts and passwords
