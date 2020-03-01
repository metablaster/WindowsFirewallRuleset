
# About this document

Default Windows firewall has bunch of predefined rules, however this project will
not make use of these rules,
because they do not comply with project policy which is that a rule must be
restrictive and contain a good comment.

For example most predefined rules do not specify remote port or address,
or are missing other information which
could be easily provided for custom built firewall, also comments are not very informative.
In other words predefined rules are neither restrictive nor informative.

Thus this project reinvents the wheel, and groups those predefined rules into
custom groups.
Custom rule groups do not interfere with predefined groups to be able to distinguish
project rules from predefined rules.

Some of the rules retain grouping while other are grouped into existing groups,
grouping exceptions are listed bellow.

# Grouping predefined rules

TODO: following information is not up to date

Predefined group or comment / new group

1. mDNS -> Basic Networking - IPv4
2. Wireless Display -> Wireless Networking
3. Cast to Device -> Additional Networking
4. Rules for store apps -> Store Apps and Store Apps - System
5. Some Core networking rules -> "ICMPv4" and Windows Services
