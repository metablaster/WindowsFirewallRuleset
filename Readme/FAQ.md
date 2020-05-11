# About this document

Here are the most common problems running powershell scripts in this project and how to resolve them.

## I applied the rule(s) but it doesn't work, program xyz.exe doesn't connect to internet

1. Close down the program which is unable to connect to network completely
2. In GPO select each rule that applies to this program, right click and disable,
   then enable again.
3. Open program in question and try again, in most cases this should work.
4. If not try rebooting system, Windows firewall sometimes just doesn't instantly respect the rules.
5. If still no luck, open rule properties in GPO and under advanced tab allow all interface types,
all users or both, however allowing all interfaces or users should be only a temporary measure.

INFO: In addition to interfaces shown in GPO there are some hidden network interfaces,
unless I figure out how to make rules based on those allow them all if this resolves the problem.

## I got an error "Network path not found"

Please make sure you have at a minimum following network services set to automatic and
make sure they are running:

1. Workstation (LanmanWorkstation)
2. Server (LanmanServer)
3. TCP/IP NetBIOS Helper service (lmhosts)

## There is no output, the script hangs and stays blank until "Enter" is pressed

This is for sure a bug, the script is waiting for input but it's not known for what exactly,
a lot of these have been fixed already, please report them if possible!
