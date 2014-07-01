openvpn-roadwarrior
-----
`openvpn-roadwarrior.sh` installs an OpenVPN server in a roadwarrior-style configuration. All client traffic, including DNS requests, will be routed through this OpenVPN server — useful for mobile users on untrusted networks, such as open Wi-Fi in coffee shops, etc.

`openvpn-roadwarrior.sh` is setup to install on CentOS 6.5 64-bit or later and Ubuntu 14.04 LTS or later systems. Older versions may require debugging of the script.

The following tasks are automated in roughly this order:

1. Install `openvpn` and `easy-rsa` packages using either CentOS or Ubuntu settings.
..+ Note that the `easy-rsa` package was previously bundled with older versions of CentOS and Ubuntu.
2. Setup `/etc/openvpn` directory and relevant sub-directories.
3. Generate certificate authority, Diffie-Hellman, server, and (1) client certificate and key pairs.
4. Create server configuration file, up/down `roadwarrior` script, and client configuration file.
5. Configure OpenVPN to work with SELinux if using CentOS.
..+ Settings are configured regardless if server is in Enforcing, Permissive, or Disabled SELinux modes.
6. Archive first client certificate and key pair as `/root/openvpn-01.tar.gz`.

### Usage

Edit the following variables as needed:

````bash
SERVER_NAME="openvpn"           # Name to use for .conf and certificate files
SERVER_IP="192.168.1.1"         # Public IP running OpenVPN service
OUTBOUND_INT="eth0"             # Public facing interface name
SERVER_NETWORK="172.16.255.0"   # Tunnel interface network
SERVER_MASK="255.255.255.0"     # Tunnel interface subnet mask
DNS_IP="8.8.8.8"                # DNS requests redirected to this DNS server
KEY_SIZE="2048"                 # Size of certificates and keys: 2048 or 4096
````

Run `./openvpn-roadwarrior` or `./openvpn-roadwarrior.sh --verbose`.
