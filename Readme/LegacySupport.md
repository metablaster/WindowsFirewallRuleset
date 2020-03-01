
# This document describes how to make use of this project on older Windows systems

**First, note that Home versions of Windows do not have GPO (Local Group Policy),
therefore not possible to make use of this project.**

To be able to apply rules to older systems such as Windows 7 or
Windows server 2008, you'll need to modify code.\
At a bare minimum you should do the following 4 modifications:

**Modification 1:**\
edit the `Modules\Project.AllPlatforms.System` to allow execution for older system.

**Modification 2:**\
edit the `Config\ProjectSettings.ps1` and define new variable that defines your
system version, following variable is defined to target Windows 10.0 editions
and above by default for all rules.\
```New-Variable -Name Platform -Option Constant -Scope Global -Value "10.0+""```

For example for Windows 7, define a new variable that looks like this:\
```New-Variable -Name PlatformWin7 -Option Constant -Scope Global -Value "6.1"```

`Platfrom` variable specifies which version of Windows the associated rule applies.\
The acceptable format for this parameter is a number in the Major.Minor format.

**Modification 3:**\
edit individual ruleset scripts, and take a look which rules you want or need to
be loaded on that system,\
then simply replace ```-Platform $Platform``` with ie.
```-Platform $PatformWin7``` for each rule you want.

In VS Code for example you can also simply (CTRL + F) for each script and replace
all instances. very simple.\
If you miss something you can delete, add or modify rules in GPO later.

Note that if you define your platform globaly (ie. ```$Platform = "6.1"```)
instead of making your own variable, just replacing the string, but do not
exclude unrelated rules, most of the rules should work, but ie. rules for
Store Apps will fail to load.\
Also ie. rules for programs and services that do not exist on system will be
most likely applied but redundant.

What this means, is, just edit the GPO later to refine your imports if you go
that route, or alternatively revisit your edits and re-run individual scripts again.

**Modification 4:**\
Visit `Test` folder and run all tests individually to confirm modules and their
functions work as expected, any failure should be fixed.
