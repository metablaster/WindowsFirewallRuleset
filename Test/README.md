
# Test directory

Root directory for all unit tests

Subfolders represent tests for individual modules or scripts.\
Root directory contains general non module and non script tests.

**NOTE:** Not all tests will run clean and some unit tests do not run by default
such as tests for experimental or unfinished code.

| Script                    | Description                                                            |
| ------------------------- | ---------------------------------------------------------------------- |
| BlankTest.ps1             | Blank test to perform experiments                                      |
| MarkdownLinkTest.ps1      | Tests validity of links in all markdown files in repository            |
| PSScriptAnalyzer.ps1      | Runs PSScriptAnalyzer on entire repository                             |
| RuleAppSID.ps1            | Experimental test to test firewall rule based on app SID               |
| RuleInterfaceAlias.ps1    | Experimental test to test firewall rule based on NIC alias             |
| RuleRelativePath.ps1      | Experimental test to test firewall rule based on relative path         |
| RuleSDDL.ps1              | Experimental test to test firewall rule based on SDDL                  |
| RunAllTests.ps1           | Runs all unit test in repository one by one                            |
| TestFileEncoding.ps1      | Verifies file encoding is correct and desired on entire repository     |
| TestModuleManifest.ps1    | Tests the syntax of module manifest file on all modules in repository  |
| TestModuleVariables.ps1   | Tests module variables of all modules in repository                    |
| TestProjectSettings.ps1   | Test Config\ProjectSettings.ps1 file                                   |
| TestScriptInfo.ps1        | Tests `PSScriptInfo` portion of all script in`Scripts` directory       |
| TestSessionConfig.ps1     | Tests all PowerShell session configuration files in repository         |
