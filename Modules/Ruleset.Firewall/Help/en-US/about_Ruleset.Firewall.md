
# Ruleset.Firewall

## about_Ruleset.Firewall

## SHORT DESCRIPTION

Windows firewall management module

## LONG DESCRIPTION

Ruleset.Firewall module is used to manage Windows firewall, for example:
Export, import and remove rules from Windows firewall, format output during rule deployment,
functionality for firewall rule and policy auditing.

## EXAMPLES

```powershell
Export-FirewallRule
```

Exports firewall rules to a CSV or JSON file

```powershell
Find-RulePrincipal
```

Get all firewall rules with or without LocalUser value

```powershell
Format-RuleOutput
```

Get firewall rules from registry

```powershell
Get-FirewallRule
```

Format output of the Net-NewFirewallRule commandlet

```powershell
Import-FirewallRule
```

Imports firewall rules from a CSV or JSON file

```powershell
Remove-FirewallRule
```

Removes firewall rules according to a list in a CSV or JSON file

## KEYWORDS

- Audit
- Firewall
- Export
- Import
- FirewallRule

## SEE ALSO

https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Modules/Ruleset.Firewall/Help/en-US
https://github.com/MScholtes/Firewall-Manager
