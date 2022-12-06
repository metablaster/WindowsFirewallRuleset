
# Config directory

Contains configuration files for by this repository and external programs.

Most of these settings are specialized for firewall management, which helps to reduce
the need to set these things over and over again.

1. `cSpell` contains spellcheck dictionaries specific for this repository
2. `RemoteFirewall.pssc` remote session configuration script.
3. `ProjectSettings.ps1` script globally affects all scripts in this repository.
4. `PSScriptAnalyzerSettings.psd1` rules for static code analysis and formatting.
5. `HelpContent` constains cabinet help content which is at the moment of no use.
6. `mTail` contains settings for mTail program.
7. `procmon` contains settings for process monitor from sysinternals.
8. `SSH` contains SSH server\client configuration for Remote SSH extension.
9. `System` contains all other (ungrouped) settings.
10. `WPA` contains settings for Windows Performance Analyzer

For more information about using these settings to configure external tools see:
[Monitoring Firewall](../docs/MonitoringFirewall.md)
