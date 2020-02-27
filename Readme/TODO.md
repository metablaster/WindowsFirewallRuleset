
# List of stuff that needs to be done

This is a project global list which applies to several or all scripts, for smaller todo's see point 1 first!

1. First do CTRL + F in VSCode and search for "TODO"
2. update FirewallParamters.md with a list of incompatible paramters for reference
3. apply local IP to all rules, as optional feature
4. Detect if script ran manually, to be able to reset errors and warning status
5. some rules are missing comments
6. auto detect interfaces
7. Now that common parameters are removed need to update the order of rule parameters, also not all are the same.
8. Implement unique names and groups for rules, -Name and -Group paramter vs -Display*
9. make display names and groups modular for easy search, ie. group - subgroup, Company - Program
10. make possible to apply or enable only rules relevant for current firewall profile
11. make possible to apply rules to remote machine, currently partially supported
12. Function to check executables for signature and virus total hash
13. Count invalid paths in each script
15. Test already loaded rules if pointing to valid program or service, also test for weakness
16. Limit code to 80-100 columns rule, subject to exceptoins
17. Provide following keywords in function comments: .DESCRIPTION .LINK .COMPONENT
18. Access is denied randomly while executing rules, need some check around this
19. Need to see which functions/commands may throw and setup try catch blocks
20. DefaultParameterSetName for functions with parameter sets is missing
21. Apply only rules for which executable exists, Test-File function
22. Implement Importing/Exporting rules.
23. Measure execution time for each or all scripts.
24. Test for 32bit powershell and OS.
25. Convert tests to use Pester if possible
26. Revisit parameter validation for functions, specifically acceptance of NULL or empty.
27. Revisit how functions return and what they return, return keyword vs Write-Output, if piping is needed after all.
28. We probalby don't need VSSetup module, other scripts and modules need to be checked for updates
29. Revisit function parameters, their types, aliases etc..
30. localhost != `[Environment]::MachineName`
31. Revisit code and make consitent PSCustomObject properties for all function outputs
32. Move NET.IP tests into test folder, clean up directory add streams
33. Paths to fix: nvidia, onedrive, visio, project rules to fix: qbittorrent, steam, vcpkg, msys2, store apps for admins, internet browser (auto loads)
34. Change bool parameters to switch where possible
35. Revisit naming convention for ConvertFrom/ConvertTo it's not clear what is being converted, some other functions also have odd names
36. Line numbers for verbose and debug messages

# Partially fixed, need testing

- Most program query functions return multiple program instances, need to select latest or add multiple rules.
