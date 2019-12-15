
# About this document
Default Widnows firewall has bunch of predefined rules, however this project will not make use of these rules,
because they do not comply with project policy which is that a rule must contain as much information as possible.

For example most predefined rules do not specify remote port or address, or are missing other information which
could be easily provided for custom built firewall, also comments are not very infomative.
In other words predefined rules are neither restrictive or informative.

Thus this project reinvents the wheel, and groups those prdefined rules into custom groups.
Custom rule groups do not interfere with predefined groups to be able to distinguish project rules from predefined rules.

Some of the rules retain grouping while other are grouped into existing groups, grouping exceptions are listed bellow.

# Grouping predefined rules
Predefined group / new group

1. mDNS -> Basic Networking
2. Wireless Display -> Wireless Networking
3. Cast to Device -> Additional Networking
