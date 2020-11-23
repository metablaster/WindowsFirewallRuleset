
# Scripts directory

Contains following project scripts which are not part of modules

1. `ExportFirewall.ps1` to export all firewall rules from GPO policy store
2. `GrantLogs.ps1` grant access to firewall log files if logged into repository
3. `HiddenProperties.ps1` to show hidden firewall rule properties
4. `ImportFirewall.ps1` to import all exported firewall rules into GPO policy store
5. `ParseAudit.ps1` to parse audit events from event log and write them to log file
6. `ResetFirewall.ps1` to restore GPO policy store to factory defaults
7. `RestartNetwork.ps1` to restart or reset network without the need for reboot
8. `SetupFirewall.ps1` to apply firewall rules and global settings to GPO
9. `SetupProfile.ps1` to apply global firewall settings (called by "SetupFirewall.ps1")
10. `UnblockProject.ps1` to unblock all files in repository (called by "SetupFirewall.ps1")
11. `UpdateHelp.ps1`  generate new or update existing help files for all project modules

**Warning:**\
Export/Import of firewall rules might take a lot of time, it is recommended to either customize these\
2 scripts to fine tune what to export or even better to use `secpol.msc` to export/import firewall.
