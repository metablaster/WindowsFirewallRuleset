
# Test directory

Root directory for all unit tests

Subfolders represent tests for individual modules or scripts.\
Root directory contains general non module and non script tests.

**NOTE:** Not all tests will run clean and some unit tests do not run by default
such as tests for experimental or unfinished code.

Detailed testing should start with `Ruleset.Test`, `Ruleset.Logging`, `Ruleset.Initialize` and
`Ruleset.Utility` before doing other tests to confirm basic functionality works, other modules
depend on these.

| Script                     | Description                                                           |
| -------------------------- | --------------------------------------------------------------------- |
| Invoke-AllTests.ps1        | Runs all unit test in repository one by one                           |
| Invoke-BlankTest.ps1       | Blank test to perform experiments                                     |
| Invoke-CodeAnalysis.ps1    | Runs PSScriptAnalyzer on entire repository                            |
| New-RuleAppSID.ps1         | Experimental test to test firewall rule based on app SID              |
| New-RuleInterfaceAlias.ps1 | Experimental test to test firewall rule based on NIC alias            |
| New-RuleRelativePath.ps1   | Experimental test to test firewall rule based on relative path        |
| New-RuleSDDL.ps1           | Experimental test to test firewall rule based on SDDL                 |
| Test-FileEncoding.ps1      | Verifies file encoding is correct and desired on entire repository    |
| Test-MarkdownLink.ps1      | Tests validity of links in all markdown files in repository           |
| Test-ModuleExports.ps1     | Unit test to test module export of all modules in repository          |
| Test-ModuleManifest.ps1    | Tests the syntax of module manifest file on all modules in repository |
| Test-ProjectSettings.ps1   | Test Config\ProjectSettings.ps1 file                                  |
| Test-ScriptInfo.ps1        | Tests `PSScriptInfo` portion of all script in`Scripts` directory      |
| Test-SessionConfig.ps1     | Tests all PowerShell session configuration files in repository        |
