/system script
add dont-require-permissions=no name=ipv6-binding-script policy=read,write source="\
    \n# This script is meant to be set as an IPv6 DHCP server binding script\
    \n# Upon DHCPv6 binding, it finds the MAC address associated with the binding using IPv6 neighbors\
    \n# It then finds the IPv4 address, and copies the address list and comments set by Sonar over to IPv6\
    \n# It assumes you are using an IPv4 dhcp server whose name is set in the variable v4server and\
    \n# an authorization list whose name is set in the variable authlist\
    \n# These are set to some defaults but you should edit them to match your network.\
    \n#\
    \n# It then creates and maintains new address list entries under the list name copied from the IPv4 list\
    \n# but with _auto appended to prevent Sonar overwriting it. You will need matching firewall and mangle rules\
    \n# for this to be of any use. The entries are set with a timeout to match the binding timout taken from the v6 DHCP server.\
    \n\
    \n:global macaddr\
    \n:global v4addr\
    \n:global v4comment\
    \n:global v4speed\
    \n:global v4server\
    \n:global authlist\
    \n:global v6leasetime\
    \n\
    \n# Set variables for your system and network here\
    \n:set v4server \"public\"\
    \n:set authlist \"non-delinquent\"\
    \n\
    \n:if (\$bindingBound = 1) do={\
    \n       :set macaddr [/ipv6 neighbor get [find where address=\$bindingAddress] mac-address]\
    \n       :log info \"AUTOV6: Mac address associated with \$bindingPrefix is \$macaddr\"\
    \n       :if ( [/ip dhcp-ser lease find where mac-address=\$macaddr and server~\"\$v4server\"] = \"\" ) do={\
    \n               :log info \"AUTOV6: Could not find IPv4 lease for mac address \$macaddr\"\
    \n       } else={\
    \n               :set v6leasetime [/ipv6 dhcp-ser get [:pick [find where name~\"\$bindingServerName\"] 0 ] lease-time]\
    \n               :set v4addr [/ip dhcp-ser lease get [:pick [find where mac-address=\$macaddr and server~\"\$v4server\"] 0 ] address ]\
    \n               :log info \"AUTOV6: IPv4 address associcated with \$macaddr is \$v4addr\"\
    \n               :if ( [/ip firewall address-list find where address=\$v4addr and list=\$authlist ] = \"\" ) do={\
    \n                       :log info \"AUTOV6: No address list entry for \$v4addr\"\
    \n               } else={\
    \n                       :set v4comment [/ip firewall address-list get [:pick [find where address=\$v4addr and list=\$authlist] 0] comment ]\
    \n                       :set v4speed [/ip firewall address-list get [:pick [find where address=\$v4addr and list!=\$authlist] 0] list ]\
    \n                       :log info \"AUTOV6: IPv4 address comment associated with \$v4addr is \$v4comment\"\
    \n                       :log info \"AUTOV6: Speed associated with \$bindingPrefix is \$v4speed\"\
    \n                       /ipv6 dhcp-server binding make-static [find where\_address=\$bindingPrefix]\
    \n                       /ipv6 dhcp-server binding set [find where address=\$bindingPrefix] comment=\$v4comment\
    \n                       /ipv6 dhcp-server binding remove [find where address!=\$bindingPrefix and comment=\$v4comment]\
    \n                       /ipv6 firewall address-list remove [find where comment=\"\$v4comment\" and list~\"_auto\"]\
    \n                       /ipv6 firewall address-list add address=\$bindingPrefix timeout=\$v6leasetime list=\"\$authlist_auto\" comment=\"\$v4comment\"\
    \n                       /ipv6 firewall address-list add address=\$bindingPrefix timeout=\$v6leasetime list=\"\$v4speed_auto\" comment=\"\$v4comment\"\
    \n                       :log info \"AUTOV6: Processing for \$v4comment complete\"\
    \n\
    \n               }\
    \n       }\
    \n}\
    \n"
