
# Problematic network traffic

**List of Windows services failing to connect outbound**

Program: `"%SystemRoot%\System32\svchost.exe"`

Cryptographic Services
- Service: `CryptSvc`
- Ports: 80, 443

Microsoft Account Sign-in Assistant
- Service: `wlidsvc`
- Ports: 443

Windows Update
- Service: `wuauserv`
- Ports: 443

Background Intelligent Transfer Service
- Service: `BITS`
- Ports: 80, 443

**Troubleshooting**
1. secpol.msc
2. Advanced Audit Policy Configuration
3. Advanced Audit Policies - Local Group Policy Object
4. Object Access
5. Audit Filtering Platform Packet drop (Audit failure)
6. Audit Filtering Platfrom Connection (Audit failure)
7. reproduce netwrok traffic failure
8. Event log -> Windows logs -> Security
9. Note "Filter Run-Time ID" number
10. run: `netsh wfp show state`
11. Open xml file and CTRL + F noted filter id
12. take a look at "displayData" node to learn what rule caused the block
13. if value is "Default Outbound" it means no specific block rule, but,
firewall is set to block all outbound by default.
and that means our allow rule did not work. (Possible bug in WFP or lack of information)
14. For more info see: https://docs.microsoft.com/en-us/windows/security/threat-protection/auditing/event-5157

**Audit result**
1. Rules based on services automatically assign SID which is service SID, and only those SID's are allowed network access.
2. All services except those listed above, do not require currently loged in user account SID, only their own SID.
3. Rules for services listed above need current user account SID, which is against the rule saying only service SID is allowed.
4. To resolve the issue define one rule for services listed above with user accounts which are allowed to use those services.
5. Note however, in Windows 10 you can't apply that rule to services, therefore a rule targets svchost and user account, not service(s)
6. That will make our firewall weaker, but it's the only way to allow those services trough firewall
if outbound traffic is blocked by default.

