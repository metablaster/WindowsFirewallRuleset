
# Config directory

Contains configuration files for this project and external programs.

Most of these settings are highly specialized for firewall management, which helps to reduce
the pain of settings these things over and over again.

1. `ProjectSettings.ps1` script globally affects all scripts in this repository.
2. `PSScriptAnalyzerSettings.psd1` contains PowerShell analyzer and code formatting rules.
3. `HelpContent` constains cabinet help content which is at the moment of no use.
4. `mTail` contains settings for mTail program.
5. `sysinternals` contains settings for tools form Microsoft's sysinternals suite.
6. `Windows` contains all other (ungrouped) settings.
7. `WPA` contains settings for Windows Performance Analyzer

For more information about using these settings to configure external tools see:
[Monitoring Firewall](Readme/Monitoring%20Firewall.md)

<!-- [Monitoring Firewall]: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Readme/Monitoring%20Firewall.md -->
