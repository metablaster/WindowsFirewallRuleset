
# How to disable Windows firewall

This document explains how to disable Windows firewall in both Control Panel and in Local group policy.
It is not recommended to disable firewall for security reasons except to troubleshoot problems.

Keep in mind that GPO firewall and control panel firewall are 2 distinct firewalls that manage same
filtering platform behind the scene.

And, GPO firewall has higher priority which makes control panel firewall not active except if
explicitly merged into GPO firewall in either GUI settings or via PowerShell.

**NOTE:** disabling firewall does not delete rules, you can enable firewall back again by following
same steps.

## Disable GPO firewall

To disable GPO firewall all you have to do is to set it to "Not Configured", which means only firewall
in control panel will be active, and GPO firewall will have no effect.

To do this follow below steps:

1. Press start button
2. type: secpol.msc
3. right click on secpol.msc and click Run as administrator
4. expand node: Windows Defender Firewall with Advanced Security
5. right click on: Windows Defender Firewall with Advanced Security - Local Group Policy Object
6. Select properties
7. There are 3 tabs: "Domain", "Private" and "Public"
8. Set "Firewall state" to "Off" for all 3 profiles and click "Apply" for each
9. You might need to reboot system if the effect is not immediate.

## Disable firewall in control panel

Disabling control panel firewall can be done in 2 ways with different results:

- Making it not active by configuring GPO firewall.
Which means GPO firewall will be active while control panel firewall will have no effect.

To disable control panel firewall so that only GPO firewall works follow below steps:

1. Press start button
2. type: secpol.msc
3. right click on secpol.msc and click Run as administrator
4. expand node: Windows Defender Firewall with Advanced Security
5. right click on: Windows Defender Firewall with Advanced Security - Local Group Policy Object
6. click "properties" in pop up menu
7. There are 3 tabs: "Domain", "Private" and "Public"
8. on each tab click under "settings" click on "Customize..." button
9. under "rule merging" set "Apply local firewall rules" to "NO"

**NOTE:** rule merging means rules from both firewalls will be active as if it's one firewall,
This is not recommended for security reasons except to troubleshoot problems.

- Disabling it in control panel
Which means it will not be active only if GPO firewall is not active too.

To disable control panel firewall so that it's disabled only if GPO firewall is disabled then
follow below steps:

1. Press start button
2. type: control panel
3. open control panel app and go to:
`Control Panel\All Control Panel Items\Windows Defender Firewall`
4. click on "Advanced settings"
5. right click on node "Windows Defender Firewall with Advanced Security on Local Computer"
6. click "properties" in pop up menu
7. There are 3 tabs: "Domain", "Private" and "Public"
8. Set "Firewall state" to "Off" for all 3 profiles and click "Apply" for each

## Disable firewall completely

If you want to make sure both GPO and control panel firewalls are disabled follow both of the above
steps but under section\
"Disable firewall in control panel" chose second steps that says "Disabling it in control panel"

You might need to reboot system if effect is not immediate.
