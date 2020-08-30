
# Scripts directory

Contains following project scripts that are not part of modules

1. `SetupFirewall.ps1` to apply firewall rules and global settings to GPO
2. `SetupProfile.ps1` to apply global firewall settings (called by "SetupFirewall.ps1")
3. `UnblockProject.ps1` to unblock all files in repository (called by "SetupFirewall.ps1")
4. `ResetFirewall.ps1` to restore GPO policy store to factory defaults
5. `ExportFirewall.ps1` to export all firewall rules from GPO policy store
6. `ImportFirewall.ps1` to import all firewall rules from GPO policy store
