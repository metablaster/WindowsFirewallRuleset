
# Scripts directory

Contains scripts which are not part of modules as follows:

| Core scripts           | Description                                                        |
| ---------------------- | ------------------------------------------------------------------ |
| Backup-Firewall.ps1    | Export all firewall rules from GPO policy store                    |
| Complete-Firewall.ps1  | Apply global firewall settings (called by "Deploy-Firewall.ps1")   |
| Deploy-Firewall.ps1    | Apply firewall rules and global settings to GPO                    |
| Grant-Logs.ps1         | Grant access to firewall log files if logged into repository       |
| Reset-Firewall.ps1     | Restore GPO policy store to factory defaults                       |
| Restore-Firewall.ps1   | Import all exported firewall rules into GPO policy store           |
| Unblock-Project.ps1    | Unblock all files in repository (called by "Deploy-Firewall.ps1")  |

---

| Utility scripts             | Description                                                          |
| --------------------------- | -------------------------------------------------------------------- |
| Debug-FilteringPlatform.ps1 | Parse audit events from event log and write them to log file         |
| Get-CallerPreference.ps1    | Fetch preference variable values from the caller's scope.            |
| Get-DevicePath.ps1          | Get mappings of disk volume letter and device path                   |
| Get-ExportedType.ps1        | Get exported types in the current session                            |
| Get-NetworkStatistics.ps1   | Display current TCP/IP connections for local or remote system        |
| Get-ParameterAlias.ps1      | Gets parameter aliases of functions, commandlets, scripts or aliases |
| Get-PropertyType.ps1        | Get .NET types for properties of one or more objects                 |
| Initialize-Development.ps1  | Initialize development environment                                   |
| Restart-Network.ps1         | Restart or reset network without the need for reboot                 |
| Select-HiddenProperty.ps1   | Get a list of hidden properties for specified firewall rule group    |
| Update-HelpContent.ps1      | Generate new or update existing help files for all project modules   |

---

| Experimental scripts  | Description                                                          |
| --------------------- | -------------------------------------------------------------------- |
| Start-PacketTrace.ps1 | Start capturing network traffic into an *.etl file for analysis      |
| Stop-PacketTrace.ps1  | Stop capturing traffic previously started with Start-PacketTrace.ps1 |

---

**Warning:**\
Export\Import of firewall rules might take a lot of time, it is recommended to either customize these\
2 scripts to fine tune what to export or even better to use `secpol.msc` to export\import firewall.
