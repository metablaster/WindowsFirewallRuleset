# How to contribute
Here is a short and most important list of things to keep in mind.

## General guidelines
Bellow 2 pages explains general/starting guidelines:\
[How to contribute to open source](https://opensource.guide/how-to-contribute)\
[Open Source Contribution Etiquette](https://tirania.org/blog/archive/2010/Dec-31.html)

First step is to fork a project:\
[Forking projects](https://guides.github.com/activities/forking)

Next you may want to set up your SSH keys (don't actually do it yet):\
[connecting-to-github-with-ssh](https://help.github.com/en/enterprise/2.20/user/github/authenticating-to-github/connecting-to-github-with-ssh)

The reason why not to set up SSH keys right away is because for PowerShell I made this tutorial:\
[PowerShell GPG4Win, SSH, posh-git](https://github.com/metablaster/DevelopmentSetup/blob/master/git/git%2C%20powershell%2C%20gpg4win%2C%20posh-git%2C%20commit%20signing%2C%20ssh%20and%20key%20caching.md)

Few additional references worth reading:\
[Don't "Push" Your Pull Requests](https://www.igvita.com/2011/12/19/dont-push-your-pull-requests)\
[Painless Bug Tracking](https://www.joelonsoftware.com/2000/11/08/painless-bug-tracking)

## Code style
All of the scripts should use the same code style and order of code, without writing a long list of preffered code style\
it should be enough to take a look at the existing scripts and figure it out right away.

Use cammel case for variables, types, symbols etc; lowercase for language keywords.

Each rule uses exactly the same order or paramters split into exactly the same number of lines.\
This is so that when you need to change or search something it's easy to see what is where right away.

The code in scripts is ordered into "sections" in following way, and may be different if needed for what ever reason:
1. License notice
2. Inclusions (modules, scripts)
3. User input
4. Installation directores
5. Removal of exiting rules
6. Rules

## Documentation and comments
Sections of code should be documented as shown in existing scripts.\
To comment on things that need to be done add "TODO:" + comment, similary for notes add "NOTE:" + comment.\
For any generic comments you may want to add use line comments (preferred) and block comments only if comment is big.

Provide documentation and official reference for your rules so that it can be easy to verify that these rules do not contain mistakes,  for example, for ICMP rules you would provide a link to [IANA](https://www.iana.org) with relevant reference document.

it is important that each rule contains good description of it's purpose, when a user clicks on a rule in firewall GUI he wants to see
what this rule is about and easily conclude whether to enable/disable the rule or allow/block the traffic.

Documentation and comments reside in 3 places:
1. In scripts (for developers)
2. In rules (for users)
3. In Readme folder (for general public)

Commenting code is as important as writing it!

## Writing rules
It is important that a rule is very specific and not generic, that means specifying protocol, IP addresses, ports, system user, interface type and other relevant information.
for example just saying: allow TCP outbound port 80 for any address or any user or no explanation what is this supposed to allow or block is not acceptable.

## Testing code
Each function should have it's own test and each test should cover as much code/test cases as possible, making changes to exiting code can then be easily tested!\
If test case/concept expands to several functions or if it completly unrelated to functions it should be a separate test.

All tests reside in "Test" folder which cotains subfolder for each module, take a look there for examples.

## Modules and 3rd party code
Project contains few custom modules of various types grouped by relevance on what the module is supposed to expose.

Try to limit dependency on 3rd party modules.\
Existing modules should be extended and new written by using Powershell only if possible.

Only if this is not enough we can try to look for 3rd party modules which could be easily customized without too much change or learning curve.

3rd party code/module license should of course be compatible with existing licenses.

## Commits and pull requests
Push small commits that solve or improve single problem, to reduce merge conflicts among other things.\
Do not wait too much to push large commits which are not clear enough in terms what issue is supposed to be resolved or improved.

**Avoid making huge changes to existing code** without first discusing the matter, new code and additions is not problem thogh.

## Portability and other systems
At the moment we focus on Windows Firewall, if you have skills to port code to other firewalls go ahead, but it's not priority.

If you decide to port code it is mandatory that these code changes are done on separate branch.

## Making new scripts
Inside "Templates" folder there are few template scripts as a starting point.\
Copy them to target location, update code and start writing.

## Repository folder structure
See [DirectoryStructure.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Readme/DirectoryStructure.md)
