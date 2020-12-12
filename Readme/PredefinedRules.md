
# Windows firewall predefined (built in) rules

Default Windows firewall has a bunch of predefined rules,
however this repository does not make much use of these rules,
because they don't comply with project policy which is that a rule(s) must be
restrictive, be differently groupped and contain a good and informative comment for end user.

For example most predefined rules don't specify remote port or address,
or are missing other information which
could be easily provided for custom built firewall, and comments are not very informative.

Thus we "reinvent the wheel", and group small portion of those predefined rules into custom groups.\
Custom rule groups don't interfere with predefined groups to be able to distinguish project rules
from predefined rules.

## Grouping predefined rules

Some of the rules retain grouping while others are grouped into existing groups,
grouping exceptions are listed below.

Predefined group -> new group

1. mDNS -> `Multicast`
2. Core Networking -> `Core Networking - IPvX`
3. Multiple rule groups related to Wireless -> `Wireless Networking`
4. AllJoyn Router, Proximity sharing, Connected devices, Cast to device -> `Additional Networking`
5. Rules for store apps -> `Store Apps` and `Store Apps - System`
6. Some Core networking rules -> `ICMP` and `Windows Services`
7. File and printer sharing -> `File and printer sharing`
8. Network Discovery -> `Network Discovery`

## Unavoidable predefined rules

There are some predefined rules we can't avoid, at least not yet!

For example, to make home group work "Network Discovery" and "File and printer sharing" is needed.\
There might be more such predefined rules which can't be easily reinvented.
