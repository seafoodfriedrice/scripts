openvpn-roadwarrior
-----
`openvpn-roadwarrior.sh` installs an OpenVPN server in a roadwarrior-style configuration. All client traffic, including DNS requests, will be routed through this OpenVPN server — useful for mobile users on untrusted networks, such as open Wi-Fi in coffee shops, etc.

`openvpn-roadwarrior.sh` is setup to install on *CentOS 6.5 64-bit or later* and *Ubuntu 14.04 LTS or later* systems. Older versions may require debugging of the script.

The following tasks are automated in roughly this order:

1. Install `openvpn` and `easy-rsa` packages using either CentOS or Ubuntu settings.
  * Note that the `easy-rsa` package was previously bundled with older versions of CentOS and Ubuntu.
2. Setup `/etc/openvpn` directory and relevant sub-directories.
3. Generate certificate authority, Diffie-Hellman, server, and (1) client certificate and key pairs.
4. Create server configuration file, up/down `roadwarrior` script, and client configuration file.
5. Configure OpenVPN to work with SELinux if using CentOS.
  * Settings are configured regardless if server is in Enforcing, Permissive, or Disabled SELinux modes.
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

Hit **ENTER** or answer **y** when prompted to sign certificate:

````
Generating a 2048 bit RSA private key
writing new private key to 'ca.key'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) []:	<ENTER>
State or Province Name (full name) []:	<ENTER>
Locality Name (eg, city) []:	<ENTER>
Organization Name (eg, company) []:	<ENTER>
Organizational Unit Name (eg, section) []:	<ENTER>
Common Name (eg, your name or your server's hostname) [openvpn]:	<ENTER>
Name [openvpn]:		<ENTER>
Email Address []:	<ENTER>
````

````
Generating a 2048 bit RSA private key
...................................+++
....................................+++
writing new private key to 'openvpn-00.key'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) []:	<ENTER>
State or Province Name (full name) []:	<ENTER>
Locality Name (eg, city) []:	<ENTER>
Organization Name (eg, company) []:		<ENTER>
Organizational Unit Name (eg, section) []:	<ENTER>
Common Name (eg, your name or your server's hostname) [openvpn-00]:
Name [openvpn-00]:	<ENTER>	
Email Address []:	<ENTER>

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:	<ENTER>
An optional company name []:	<ENTER>
Using configuration from /etc/openvpn/easy-rsa/openssl.cnf
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :PRINTABLE:'openvpn-00'
name                  :PRINTABLE:'openvpn-00'
Certificate is to be certified until Jun 28 06:17:22 2024 GMT (3650 days)
Sign the certificate? [y/n]: y

1 out of 1 certificate requests certified, commit? [y/n] y
Write out database with 1 new entries
Data Base Updated
````

````
Generating a 2048 bit RSA private key
writing new private key to 'openvpn-01.key'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) []:	<ENTER>
State or Province Name (full name) []:	<ENTER>
Locality Name (eg, city) []:	<ENTER>
Organization Name (eg, company) []:	<ENTER>
Organizational Unit Name (eg, section) []:	<ENTER>
Common Name (eg, your name or your server's hostname) [openvpn-01]:	<ENTER>
Name [openvpn-01]:	<ENTER>
Email Address []:	<ENTER>

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:	<ENTER>
An optional company name []:	<ENTER>
Using configuration from /etc/openvpn/easy-rsa/openssl.cnf
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :PRINTABLE:'openvpn-01'
name                  :PRINTABLE:'openvpn-01'
Certificate is to be certified until Jun 28 06:17:32 2024 GMT (3650 days)
Sign the certificate? [y/n]: y
````

### Client Configuration

Client files are archived in `/root` as `openvpn-01.tar.gz`. Extract the `.conf` file into `/etc/openvpn` and the certificate key files to `/etc/openvpn/keys`.

Note that the extension of the `.conf` file should be changed to `.ovpn` for OpenVPN clients using Windows.
