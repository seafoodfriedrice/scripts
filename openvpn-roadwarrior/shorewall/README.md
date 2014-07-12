Shorewall configuration for openvpn-roadwarrior.sh
-----
Place configuration files for `/etc/shorewall` directory. Relevant contents of configuration files are shown below for quick reference.

If using the Shorewall configuration files the `/etc/openvpn/scripts/roadwarrior` script should be disabled in the OpenVPN server configuration because the `masq` and `rules` files handle the DNS redirect and tunnel interface masquerading. 

````
#up /etc/openvpn/scripts/roadwarrior
#plugin /usr/lib/openvpn/openvpn-plugin-down-root.so /etc/openvpn/scripts/roadwarrior
````

###### /etc/shorewall/params

````
#
# Shorewall version 4 - Params File
#
# /etc/shorewall/params
#
#	Assign any variables that you need here.
#
#	It is suggested that variable names begin with an upper case letter
#	to distinguish them from variables used internally within the
#	Shorewall programs
#
#	Example:
#
#		NET_IF=eth0
#		NET_BCAST=130.252.100.255
#		NET_OPTIONS=routefilter,norfc1918
#
#	Example (/etc/shorewall/interfaces record):
#
#		net	$NET_IF		$NET_BCAST	$NET_OPTIONS
#
#	The result will be the same as if the record had been written
#
#		net	eth0		130.252.100.255	routefilter,norfc1918
#
###############################################################################
NET_IF=eth0
IF_OPTIONS=arp_filter,dhcp,nosmurfs,routefilter,tcpflags
ROAD_IF=tun0
ROAD_NET=172.24.233.0/24
DNAT_DNS=8.8.8.8		# Google DNS
#LAST LINE -- DO NOT REMOVE
````

###### /etc/shorewall/interfaces

````
#
# Shorewall version 4 - Interfaces File
#
# For information about entries in this file, type "man shorewall-interfaces"
#
# The manpage is also online at
# http://www.shorewall.net/manpages/shorewall-interfaces.html
#
###############################################################################
?FORMAT 2
###############################################################################
#ZONE		INTERFACE		OPTIONS
-		lo			ignore
net		$NET_IF			$IF_OPTIONS	
road		$ROAD_IF		$IF_OPTIONS	
````

###### /etc/shorewall/zones

````
#
# Shorewall version 4 - Zones File
#
# For information about this file, type "man shorewall-zones"
#
# The manpage is also online at
# http://www.shorewall.net/manpages/shorewall-zones.html
#
###############################################################################
#ZONE	TYPE		OPTIONS		IN			OUT
#					OPTIONS			OPTIONS
fw	firewall
net	ipv4
road	ipv4
````

###### /etc/shorewall/masq

````
#
# Shorewall version 4 - Masq file
#
# For information about entries in this file, type "man shorewall-masq"
#
# The manpage is also online at
# http://www.shorewall.net/manpages/shorewall-masq.html
#
###############################################################################
#INTERFACE:DEST		SOURCE		ADDRESS		PROTO	PORT(S)	IPSEC
#
$NET_IF			$ROAD_NET
````

###### /etc/shorewall/policy

````
#
# Shorewall version 4 - Policy File
#
# For information about entries in this file, type "man shorewall-policy"
#
# The manpage is also online at
# http://www.shorewall.net/manpages/shorewall-policy.html
#
###############################################################################
#SOURCE	DEST	POLICY		LOG	LIMIT:		CONNLIMIT:
#				LEVEL	BURST		MASK
$FW	net	ACCEPT
$FW	road	REJECT		info
road	net	ACCEPT
road	$FW	ACCEPT
net	all	DROP		info
````

###### /etc/shorewall/rules

````
#
# Shorewall version 4 - Rules File
#
# For information on the settings in this file, type "man shorewall-rules"
#
# The manpage is also online at
# http://www.shorewall.net/manpages/shorewall-rules.html
#
###############################################################################
#ACTION		SOURCE		DEST		PROTO	DEST	SOURCE
#							PORT	PORT(S)
#SECTION ALL
#SECTION ESTABLISHED
#SECTION RELATED
#SECTION INVALID
#SECTION UNTRACKED
SECTION NEW

Invalid(DROP)	net		$FW		all
Ping(ACCEPT)	net,road	$FW
SSH(ACCEPT)	net,road	$FW
OpenVPN(ACCEPT)	net		$FW
DNS(DNAT)	road		net:$DNAT_DNS		# DNS redirect
````
