
# How to contribute

You can use this document not only to see how to contribute code but also to prepare yourself to
extend this firewall project for your own personal or corporate needs.

Here is a list of most important things to keep in mind.

## General guidelines

Below 2 pages explain general/starting guidelines regarding open source:\
[How to contribute to open source](https://opensource.guide/how-to-contribute)\
[Open Source Contribution Etiquette](https://tirania.org/blog/archive/2010/Dec-31.html)

First step is to fork a project:\
[Forking projects](https://guides.github.com/activities/forking)

Next if needed, you might want to set up your SSH keys (don't actually do it yet):\
[Connecting to GitHub with SSH](https://help.github.com/en/enterprise/2.20/user/github/authenticating-to-github/connecting-to-github-with-ssh)

The reason why not to set up SSH keys right away is because for PowerShell I made this tutorial:\
[PowerShell GPG4Win, SSH, posh-git](https://gist.github.com/metablaster/52b1baac5be44e2f1e6d16800813f42f)

Regarding license and Copyright practices adopted by this project see:\
[Maintaining file-scope copyright notices](https://softwarefreedom.org/resources/2012/ManagingCopyrightInformation.html#maintaining-file-scope-copyright-notices)\
[Requirements under U.S. and E.U. Copyright Law](http://softwarefreedom.org/resources/2007/originality-requirements.html)

Regarding versioning adopted see:\
[Semantic Versioning 2.0.0](https://semver.org)

Few additional references regarding open source worth reading:\
[Don't "Push" Your Pull Requests](https://www.igvita.com/2011/12/19/dont-push-your-pull-requests)\
[Painless Bug Tracking](https://www.joelonsoftware.com/2000/11/08/painless-bug-tracking)

And references for tools used by this project:\
[PowerShell documentation](https://docs.microsoft.com/en-us/powershell/scripting/how-to-use-docs?view=powershell-7.1)\
[Visual Studio Code](https://code.visualstudio.com/docs)

## Environment setup

It is highly recommended to stick with Visual Studio Code, because this project includes settings
specific to Visual Studio Code, aka. "Workspace", these settings include:

1. Code formatting settings which are automatically enforced, and can also be manually applied
2. List of recommended extensions which are automatically listed for installation when you open
project root folder
3. Debugging and code analysis settings which you can use to debug code
4. Settings for recommended extensions, ex. markdown and script formatting
5. Spelling settings such as random good words which would be detected as misspelled.
6. Many other minor workspace settings to improve coding experience

To be able to open Windows PowerShell quickly in any folder see
[Right click "Open PowerShell here" context menu](https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Readme/WindowsPowerShell.md#right-click-open-windows-powershell-here-context-menu)

Recommended extensions in workspace are as follows:

1. [TODO tree](https://marketplace.visualstudio.com/items?itemName=Gruntfuggly.todo-tree)

    Required to easily navigate TODO, HACK and NOTE comments located in source files.

2. [PowerShell](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell)

    Should be obvious, syntax highlighting, intellisense, formatting etc.

3. [Markdownlint](https://marketplace.visualstudio.com/items?itemName=DavidAnson.vscode-markdownlint)

    Helps to format and write better markdown, you get a list of problems in VSCode and fix them.

4. [Code Spell Checker](https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker)

    Helps to spell words correctly, you get a list of misspelled words in VSCode and fix them

5. [Highlight Dodgy Characters](https://marketplace.visualstudio.com/items?itemName=nachocab.highlight-dodgy-characters)

    Helps to detect bad chars aka. gremlins, which cause issues such as unable to save file
    in UTF-8 format

6. [Bookmarks](https://marketplace.visualstudio.com/items?itemName=alefragnani.Bookmarks)

    Helps you to bookmark various places in project to easily navigate back and forth.

7. [Rainbow CSV](https://marketplace.visualstudio.com/items?itemName=mechatroner.rainbow-csv)

    Firewall rules can be exported into CSV file, this extension provides syntax highlighting for
    CSV files

8. [GitLens](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens)

    It provides so many great features for git inside VSCode it can't be explained in one line

9. [Markdown All in One](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one)

    Provides markdown language features

10. [XML Tools](https://marketplace.visualstudio.com/items?itemName=DotJoshJohnson.xml)

    Useful module xml files navigation

The continuation of before mentioned link for PowerShell, gpg, ssh etc. is to visit `Config\ProjectSettings.ps1`
located in project root directory, at a minimum you should set following variables to `$true`
before doing anything else:

1. Develop
2. ProjectCheck
3. ModulesCheck
4. ServicesCheck
5. ErrorLogging
6. WarningLogging

Note that some of these may be auto adjusted after setting `Develop` to `$true`\
Then restart PowerShell and run `.\SetupFirewall.ps1` to apply firewall, or at least run
`Initialize-Project` function which will prompt you to perform recommended and required checks.

Detailed description of variables is located in `Config\ProjectSettings.ps1`

After project was intialized `ProjectCheck` variable should be disabled, logging variables can be
disabled too.

If you don't have this environment setup, you'll have to do this some other way around for your
code editor and the rest of environment.

## Code style

### Automatic formatting

This workspace includes code formatting settings, which means you don't have to spend time formatting
source files manually, otherwise it's enough to right click into VSCode and select "Format document".

Lines should be kept within 100-120 columns, however it is not always practical, so it's not a hard
rule, workspace settings are configured to show rulers inside code editor.

If you use some other code editor you should configure it according to these rules which are found
in `.vscode`, `Config` and project root directory.

### Rationale

All of the scripts should use the same code style and order of code,
without writing a long list of preferred code style\
it should be enough to take a look at the existing scripts and figure it out right away.

Not everything is automatically formatted, in short:\
Use **PascalCase** for variables, types, symbols etc; **lowercase** for language keywords,
for more info about type casing run:

```powershell
[PSCustomObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::get.GetEnumerator() | Sort-Object Key
```

Following link describes general rules about PowerShell code style if you like reading,
however keep in mind, it is not in line of this project practices:\
[The PowerShell Style Guide](https://poshcode.gitbooks.io/powershell-practice-and-style/Style-Guide/Introduction.html)

### Rule design

Each firewall rule uses exactly the same order or parameters split into exactly the same number of lines.\
This is so that when you need to change or search for something or do some regex magic then it's
easy to see what is where right away.

Performing regex operations against firewall rules in combination with multicursor feature can be
done in a matter of minutes, without this strict rule design it would take an entry day and might
result in serious bugs or security issues!

The code in rule scripts is ordered into "sections" in the following way,
and may be different if needed for what ever reason:

1. License notice
2. Inclusions (modules, scripts)
3. User input
4. Installation directories
5. Removal of exiting rules
6. Rules

## Modules and 3rd party code

The project contains few custom modules of various type grouped by relevance on
what the module is supposed to expose.

Try to limit dependency on 3rd party modules.\
Existing modules should be extended and new written by using Powershell only if possible.

Only if this is not enough we can try to look for 3rd party modules which could be
easily customized without too much change or learning curve.

3rd party code/scripts are dot sourced into existing modules instead of copy pasted into module
directly, this must be so, to easily see to which file does license/Copyright apply in full.

3rd party code/module license/Copyright must of course be retained and compatible with existing licenses.

## Module design

Rules for code in modules is different, most important is to keep each function in it's own script,
separated into Public/Private folders, this is required for 2 valid reasons:

1. To perform tests on private functions without exporting them from module
2. For organizational purposes, to make it easy to maintain and navigate modules.

Module naming convention consists of 3 words like this:

`Origin.Platform.Purpose`

For example:

1. `Project.Windows.ComputerInfo`
2. `Project.AllPlatforms.Utility`

3rd party modules must not follow this naming convention, that's what word "Project" means here,
to distinguish project modules from 3rd party code.

## Static analysis

[PSStaticAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)
is used to perform basic code quality analysis.

The workspace includes static analysis settings file, so all you have to do is cd into project
root directory and invoke analyzer as follows:

```powershell
Invoke-ScriptAnalyzer -Path .\ -Recurse -Settings Config\PSScriptAnalyzerSettings.psd1
```

`PSScriptAnalyzerSettings.psd1` settings file includes all rules, including code formatting rules.

If you get an error such as:\
`Invoke-ScriptAnalyzer: Object reference not set to an instance of an object.`\
then try again and keep repeating until OK.

## Documentation and comments

Sections of code should be documented as shown in existing scripts.\
To comment on things that need to be done add "TODO:" + comment,
similarly for important notes add "NOTE:" + comment.\
For any generic comments you might want to add, use line comments (preferred) and
block comments only if comment is big.

Provide documentation and official reference for your rules so that it can be easy to verify that
these rules do not contain mistakes,  for example,
for ICMP rules you would provide a link to [IANA](https://www.iana.org)
with relevant reference document.

For things which are hard to resolve add "HACK:" + comment, and optionally some links such as github
issues that may help to resolve problem in the future.

it is important that each rule contains good description of it's purpose,
when a user clicks on a rule in firewall GUI he wants to see
what this rule is about and easily conclude whether to enable/disable rule or
allow/block network traffic.

For comment based help see:

1. [About Comment-based Help](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-7)
2. [Examples of Comment-Based Help](https://docs.microsoft.com/en-us/powershell/scripting/developer/help/examples-of-comment-based-help?view=powershell-7)

Documentation and comments reside in 4 places:

1. In scripts (for developers)
2. In rules (for users)
3. In comment based help (for module users)
4. In Readme folder (for detailed project documentation)

Remember, commenting code is as important as writing it!

## Writing rules

It is important that a rule is very specific and not generic, that means specifying protocol,
IP addresses, ports, system user, interface type and other relevant information.

For example just saying: allow TCP outbound port 80 for any address or any user or
no explanation what is this supposed to allow or block is not acceptable.

## Testing code

Each function should have it's own test script and each test should cover as much code/test
cases as possible, making changes to exiting code can then be easily tested.\
If test case/concept expands to several functions or if it's completely
unrelated to functions it should be a separate test.

All tests reside in "Test" folder which contains subfolder for each module,
take a look there for examples.

Pester is preferred method to write tests, however some testings needs other way around, or
more specialized setup.

There is a module called "Project.AllPlatforms.Test", which is customized for this project.\
Tests must pass both Desktop and Core editions of PowerShell to be successful

## Commits and pull requests

Push small commits that solve or improve single or specific problem,
to reduce merge conflicts and to be able to do `git revert` for specific stuff.

Do not wait too much to push large commits which are not clear enough in terms
what issue is supposed to be resolved or improved.

If you see something unrelated that could be resolved, put TODO commont, don't fix it.\
Then once you commit open todo-tree to review what to do next.

**Avoid making huge changes to existing code** without first discussing the matter,
new code and additions is not problem though.

## Portability and other systems

At the moment the focus is on Windows Firewall, if you want to port code to other firewalls go ahead.

If you decide to port code it is mandatory that these code changes are done on separate branch.

The plan is to expand this project to manage [nftables](https://en.wikipedia.org/wiki/Nftables)
firewall on linux and other systems.

## Making new scripts or modules

Inside "Templates" folder there are few template scripts as a starting point.\
Copy them to target location, update code and start writing.

These templates are fully aligned to rule design, code and formatting style of this project.

## Repository folder structure

See [DirectoryStructure.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Readme/DirectoryStructure.md)

## Final notes and where to start

Please keep in mind that large amount of existing code is not in line with all the guidelines
described here, significant portion of code was written before this "CONTRIBUTING" file even existed.

So it's an ongoing effort that by no means gets fulfilled.

I recommend you start at looking into [TODO](https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Readme/TODO.md)
list and also use "todo-tree" extension to see even more todo's, unless you have specific ideas or
recommendations.
