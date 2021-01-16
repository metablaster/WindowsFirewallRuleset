
# How to disable Windows firewall

This document explains how to disable Windows firewall in Control Panel and/or in Local group policy.
It is not recommended to disable firewall for security reasons except to troubleshoot problems.

Keep in mind that GPO firewall and Control Panel firewall are 2 distinct "firewalls" that let you
manage the same filtering platform behind the scene.

GPO firewall has higher priority which makes Control Panel firewall not active except if
explicitly merged into GPO firewall in either GUI settings or with PowerShell.

**NOTE:** Disabling firewall does not delete rules, you can enable firewall back again by following
same steps.

## Disable GPO firewall

To disable GPO firewall all you have to do is to set it to `Not Configured`, which means only firewall
in Control Panel will be active, and GPO firewall will have no effect.

To do this follow steps below:

1. Press start button
2. Type: `secpol.msc`
3. Right click on secpol.msc and click `Run as administrator`
4. Expand node: `Windows Defender Firewall with Advanced Security`
5. Right click on: `Windows Defender Firewall with Advanced Security - Local Group Policy Object`
6. Select `properties` in pop up menu
7. There are 3 tabs: `Domain`, `Private` and `Public`
8. Set "Firewall state" to `Not Configured` for all 3 profiles and click "Apply" for each
9. You might need to reboot system if the effect is not immediate.

## Disable firewall in Control Panel

Disabling Control Panel firewall can be done in 2 ways with different results:

### Make Control Panel firewall not active by configuring GPO firewall

Which means GPO firewall will be active only when GPO firewall is disbled.

To disable Control Panel firewall so that only GPO firewall works follow steps below:

1. Press start button
2. Type: `secpol.msc`
3. Right click on secpol.msc and click `Run as administrator`
4. Expand node: `Windows Defender Firewall with Advanced Security`
5. Right click on: `Windows Defender Firewall with Advanced Security - Local Group Policy Object`
6. Select `properties` in pop up menu
7. There are 3 tabs: `Domain`, `Private` and `Public`
8. On each tab click under `settings` click on `Customize...` button
9. Under `Rule merging` set `Apply local firewall rules` to `No`

**NOTE:** Rule merging means rules from both firewalls will be active as if it's one firewall,
This is not recommended for security reasons except to troubleshoot problems.

### Make Control Panel firewall not active in Control Panel

Which means it will not be active even if GPO firewall is disabled.

To disable Control Panel firewall so that it's disabled only if GPO firewall is disabled then first
step is to temporarily set GPO firewall to\
`Not Configured` which is explained above in section "Disable GPO firewall"

Next follow steps below:

1. Press start button
2. Type: `Control Panel`
3. Open Control Panel app and go to:
`Control Panel\All Control Panel Items\Windows Defender Firewall`
4. Click on `Advanced settings`
5. Right click on node `Windows Defender Firewall with Advanced Security on Local Computer`
6. Select `properties` in pop up menu
7. There are 3 tabs: `Domain`, `Private` and `Public`
8. Set `Firewall state` to `Off` for all 3 profiles and click `Apply` for each

When done re-enable GPO firewall

## Disable firewall completely

If you want to make sure both GPO and Control Panel firewalls are allways disabled follow section\
"Make Control Panel firewall not active in Control Panel" but do not re-enable GPO firewall at the end.

You might need to reboot system if the effect is not immediate.
