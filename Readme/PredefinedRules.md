
# Windows firewall predefined (built in) rules

Default Windows firewall has a bunch of predefined rules,
however this project will not make use of these rules,
because they don't comply with project policy which is that a rule(s) must be
restrictive, be adequately groupped and contain a good comment for end user.

For example most predefined rules don't specify remote port or address,
or are missing other information which
could be easily provided for custom built firewall, also comments are not very informative.

Thus we "reinvent the wheel", and group those predefined rules into custom groups.
Custom rule groups don't interfere with predefined groups to be able to distinguish project rules
from predefined rules.

## Grouping predefined rules

Some of the rules retain grouping while others are grouped into existing groups,
grouping exceptions are listed below.

Predefined group -> new group

1. mDNS -> Basic Networking - IPv4
2. Wireless Display -> Wireless Networking
3. Cast to Device -> Additional Networking
4. Rules for store apps -> Store Apps and Store Apps - System
5. Some Core networking rules -> "ICMPv4" and Windows Services

## Unavoidable predefined rules

There are some predefined rules we can't avoid, at least not yet!

For example, to make home group work "Network Discovery" and "File and printer sharing" is needed.\
There might be more such predefined rules which can't be easily reinvented.
