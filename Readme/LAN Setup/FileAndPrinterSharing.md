
# File and Printer Sharing

1. Enable SMB Direct. (In program features)

    For older USB network drive or connecting to an older Windows than Windows 10 SMB1 might be required.\
    You will/might need to enable SMB1 in following cases:

    - Connecting to an older Windows than Windows 10
    - An older USB network drive
    - Using the Windows 10 Home edition

    If you enable SMB1, be sure to uncheck Automatic Removal.

2. Enable use sharing wizard in folder options.

3. If some computers are on Wi-Fi network, set entry LAN to Private network profile
   (this notes assume all LAN computer have private profile set)

4. Control Panel\All Control Panel Items\Network and Sharing Center\Advanced sharing settings

   - Private profile:
     - Turn on network discovery and file and printer sharing, and turn automatic setup of network
       connected devices

   - Guest or Public profile:
     - Turn off network discovery and file and printer sharing.

   - All networks:
     - Turn on password protected sharing.
     - Use 128 bit encryption
     - Turn off public folder sharing.

5. Configure all firewalls in the network to allow File and Printer sharing rules.
