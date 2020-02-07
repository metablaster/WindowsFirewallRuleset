# List of stuff that needs to be done

1. make a list of system environment variables that are recognized by firewall, then update rules.
2. update FirewallParamters with a list of incompatible paramters for reference
3. apply local IP to all rules
4. separate config file for installation directories, or a script which would auto detect installed programs.
5. some rules are missing comments
6. auto detect interfaces
7. CTRL + F and search for "TODO"
8. Implement unique names and groups for rules, -Name and -Group paramter vs -Display*
9. make display names and groups modular for easy search, ie. group - subgroup, Company - Program
10. make possible to apply or enable only rules relevant for current firewall profile
11. make possible to apply rules to remote machine, currently partially supported
12. Function to check executables for signature and virus total hash
13. Count invalid paths in each script
14. Write warnings, errors and notes etc. to file
15. Test already loaded rules if pointing to valid program or service, also test for weakness
16. Limit code to 80 columns rule
17. Detect if script ran manually, to be able to reset errors and warning status
