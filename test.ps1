
# Remove previous test
Remove-NetFirewallRule -PolicyStore "localhost" -Group "Test" -Direction Inbound -ErrorAction SilentlyContinue
Remove-NetFirewallRule -PolicyStore "localhost" -Group "Test" -Direction Outbound -ErrorAction SilentlyContinue

New-NetFirewallRule -ErrorAction Stop -PolicyStore "localhost" `
-DisplayName "Test Rule" -Service Any -Program Any `
-Enabled False -Action Allow -Group "Test" -Profile Domain -InterfaceType Any `
-Direction Inbound -Protocol UDP -LocalAddress Any -RemoteAddress PlayToDevice -LocalPort PlayToDiscovery -RemotePort Any `
-LocalUser Any -EdgeTraversalPolicy Block

# New-NetFirewallRule -ErrorAction Stop -PolicyStore "localhost" `
# -DisplayName "Test Rule" -Service Any -Program Any `
# -Enabled False -Action Allow -Group "Test" -Profile Domain -InterfaceType Any `
# -Direction Inbound -Protocol TCP -LocalAddress Any -RemoteAddress IntranetRemoteAccess -LocalPort Any -RemotePort Any `
# -EdgeTraversalPolicy Block
