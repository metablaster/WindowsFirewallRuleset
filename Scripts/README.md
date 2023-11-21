
# Scripts directory

Contains scripts which are not part of modules as follows:

| Core scripts          | Description                                                       |
| --------------------- | ----------------------------------------------------------------- |
| Backup-Firewall.ps1   | Export all firewall rules from GPO policy store                   |
| Complete-Firewall.ps1 | Apply global firewall settings (called by "Deploy-Firewall.ps1")  |
| Deploy-Firewall.ps1   | Apply firewall rules and global settings to GPO                   |
| Grant-Logs.ps1        | Grant access to firewall log files if logged into repository      |
| Reset-Firewall.ps1    | Reset GPO policy store to system defaults                         |
| Restore-Firewall.ps1  | Import all exported firewall rules into GPO policy store          |
| Unblock-Project.ps1   | Unblock all files in repository (called by "Deploy-Firewall.ps1") |

---

| Utility scripts             | Description                                                          |
| --------------------------- | -------------------------------------------------------------------- |
| Debug-FilteringPlatform.ps1 | Parse audit events from event log and write them to log file         |
| Get-CallerPreference.ps1    | Fetch preference variable values from the caller's scope.            |
| Get-DevicePath.ps1          | Get mappings of disk volume letter and device path                   |
| Get-ExportedType.ps1        | Get exported types in the current session                            |
| Get-NetworkStat.ps1         | Display current TCP/IP connections for local or remote system        |
| Get-ParameterAlias.ps1      | Gets parameter aliases of functions, commandlets, scripts or aliases |
| Get-PropertyType.ps1        | Get .NET types for properties of one or more objects                 |
| Restart-Network.ps1         | Restart or reset network without the need for reboot                 |
| Select-HiddenProperty.ps1   | Get a list of hidden properties for specified firewall rule group    |
| Update-HelpContent.ps1      | Generate new or update existing help files for all project modules   |
| Write-RepoStats.ps1         | Calculates repository stats such as count of files or LOC            |

---

| Security scripts      | Description                                                        |
| --------------------- | ------------------------------------------------------------------ |
| Deploy-ASR.ps1        | Deploy attack surface reduction (ASR) rules                        |
| Find-UnsignedFile.ps1 | Scan executables for digital signature and check VirusTotal status |
| Remove-ASR.ps1        | Remove all or specified ASR rules                                  |
| Set-ATP.ps1           | Sets the Advanced Threat Protection (ATP) settings                 |
| Set-Privacy.ps1       | Configures Windows privacy in a restrictive way                    |
| Show-ASR.ps1          | Show current attack surface reduction (ASR) rules configuration    |

---

| Experimental scripts       | Description                                                          |
| -------------------------- | -------------------------------------------------------------------- |
| Add-WTContext.ps1          | Script to add Windows Terminal context menu in Windows 10            |
| Confirm-Firewall.ps1       | Validate firewall configuration and rules are in desired state       |
| Connect-IPInterface.ps1    | Troubleshooting script to connect NIC to network using DHCP          |
| Initialize-Development.ps1 | Initialize development environment                                   |
| New-SDDL                   | Generate custom SDDL string by using a security dialog               |
| Start-PacketTrace.ps1      | Start capturing network traffic into an *.etl file for analysis      |
| Stop-PacketTrace.ps1       | Stop capturing traffic previously started with Start-PacketTrace.ps1 |

---
