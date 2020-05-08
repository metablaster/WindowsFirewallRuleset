# About this document

Here are the most common problems running powershell scripts in this project and how to resolve them.

## I applied the rule(s) but it doesn't work, program xyz.exe doesn't connect to internet

1. Close down the program which is unable to connect to network completely
2. In GPO select each rule that applies to this program, right click and disable,
   then enable again.
3. Open program in question and try again, if rule is OK this should work!

## I got an error "Network path not found"

Please make sure you have at a minimum following network services set to automatic and make sure they are running:

1. Workstation (LanmanWorkstation)
2. Server (LanmanServer)
3. TCP/IP NetBIOS Helper service (lmhosts)

## There is no output, the script hangs and stays blank until "Enter" is pressed

This is for sure a bug, the script is waiting for input but it's not known for what exactly,
a lot of these have been fixed already, please report them if possible!
