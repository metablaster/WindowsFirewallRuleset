
# Firewall-Manager

There is only one possibility to export and import firewall rules: as a blob (wfw file) in the
firewall console or with a script.

If you want to automate removing or editing a rule from the set there is no (easy) way to do it
without using a third party tool or messing with the registry in dangerous places.

The three commandlets ExportFirewallRules, ImportFirewallRules and RemoveFirewallRules export,
import and remove complete firewall rule sets in CSV or JSON file format.
When importing existing rules with the same display name will be overwritten.

Requires Windows 8.1 / Server 2012 R2 or above.

By Markus Scholtes, 2020

## Installation

```powershell
PS C:\> Install-Module Firewall-Manager
```

(on Powershell V4 you might have to install PowershellGet before) or download from here:
https://www.powershellgallery.com/packages/Firewall-Manager

See the script version web page too:
[Powershell scripts to export and import firewall rules](https://gallery.technet.microsoft.com/Powershell-to-export-and-23287694).

## Functions

### Export-FirewallRules

```powershell
Export-FirewallRules [[-Name] <Object>] [[-CSVFile] <Object>] [-JSON] [-Inbound] [-Outbound] [-Enabled] [-Disabled] [-Allow] [-Block]

Exports firewall rules to a CSV or JSON file.

-Name   Displayname of the rules to be processed. Wildcard character * is allowed. Default: *
-CSVFile   Output file. Default: .\Firewall.csv
-JSON   Output in JSON instead of CSV format. Default: $false
-Inbound -Outbound -Enabled -Disabled -Allow -Block   Filter which rules to export
```

### Import-FirewallRules

```powershell
Import-FirewallRules [[-CSVFile] <Object>] [-JSON]

Imports firewall rules from a CSV or JSON file.

-CSVFile    Input file. Default: .\Firewall.csv
-JSON    Input in JSON instead of CSV format. Default: $false
```

### Remove-FirewallRules

```powershell
Remove-FirewallRules [[-CSVFile] <Object>] [-JSON]

Remove firewall rules according to the list in a CSV or JSON file.

-CSVFile    Input file. Default: .\Firewall.csv
-JSON    Input in JSON instead of CSV format. Default: $false
```

## Examples

```powershell
PS C:\> # Export all firewall rules to the CSV file FirewallRules.csv in the current directory:
PS C:\> Export-FirewallRules
PS C:\>
PS C:\> # Export all inbound and allowing firewall rules to the CSV file FirewallRules.csv in the current directory:
PS C:\> Export-FirewallRules -Inbound -Allow
PS C:\>
PS C:\> # Export all SNMP firewall rules to the JSON file SNMPRules.json:
PS C:\> Export-FirewallRules snmp* SNMPRules.json -json
PS C:\>
PS C:\> # Imports all firewall rules in the CSV file FirewallRules.csv in the current directory:
PS C:\> Import-FirewallRules
PS C:\>
PS C:\> # Imports all firewall rules in the JSON file WmiRules.json:
PS C:\> Import-FirewallRules WmiRules.json -json
```

## Remarks

There might be issues when importing rules for "metro apps" to another computer.

App packet rules are stored as a SID and usually apply only to user accounts whose SIDs are stored
in the export file. Those rules will normally not work on another computer since a SID is unique.

## Versions

### 1.0.2, 2020-02-17

Initial release
