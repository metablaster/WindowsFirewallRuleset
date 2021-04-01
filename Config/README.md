
# Config directory

Contains configuration files for this project and external programs.

Most of these settings are specialized for firewall management, which helps to reduce
the need to set these things over and over again.

1. `ProjectSettings.ps1` script globally affects all scripts in this repository.
2. `PSScriptAnalyzerSettings.psd1` contains rules for static code analysis and formatting.
3. `HelpContent` constains cabinet help content which is at the moment of no use.
4. `mTail` contains settings for mTail program.
5. `SSH` contains SSH server\client configuration for remote SSH development.
6. `sysinternals` contains settings for tools form Microsoft's sysinternals suite.
7. `Windows` contains all other (ungrouped) settings.
8. `WPA` contains settings for Windows Performance Analyzer

For more information about using these settings to configure external tools see:
[Monitoring Firewall](../Readme/MonitoringFirewall.md)
