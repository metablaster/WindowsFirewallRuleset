
# About this document

A list of regex expressions which are used to perform bulk operations against the rules inside the
project.

For example once your regex hits, you would use CTRL + SHIFT + L to enter multi cursor mode
and manipulate all regex matches however you like.

NOTE: firewall rule examples here are shortened.\
NOTE: regex examples may have space in the beginning or at the end, make sure to copy/paste right.

# Get -DisplayName parameter + initial space and it's value

In bellow example multi cursor-ing all the matches in a script would allow to cut and paste all
regex matches onto a second line by using CTRL + X, Down Arrow to move and CTRL + V.

```powershell
New-NetFirewallRule -DisplayName "Interface-Local Multicast" -Service Any `
-Platform $Platform -Program Any
```

```regex
 -DisplayName "(.*)"(?= -Service)
```

# Get local and remote port parameters and values

Here for example we want `-LocalPort Any -RemotePort 547`

```powershell
New-NetFirewallRule -LocalPort Any -RemotePort 547
New-NetFirewallRule -LocalPort 546 -RemotePort IPHTTPSout
```

```regex
-LocalPort (\w+) -RemotePort (\w+) ?
```
