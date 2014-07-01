#!/bin/bash
#
# openvpn-roadwarrior.sh:
#
# Install OpenVPN in roadwarrior-style configuration, i.e. all
# client traffic will be routed through this OpenVPN server.
#
SERVER_NAME="openvpn"           # Name to use for .conf and certificate files
SERVER_IP="192.168.1.1"         # Public IP running OpenVPN service
OUTBOUND_INT="eth0"             # Public facing interface name
SERVER_NETWORK="172.16.255.0"   # Tunnel interface network
SERVER_MASK="255.255.255.0"     # Tunnel interface subnet mask
DNS_IP="8.8.8.8"                # DNS requests redirected to this DNS server
KEY_SIZE="2048"                 # Size of certificates and keys: 2048 or 4096

if [ $(id -u) -ne 0 ]; then
    echo "$(basename $0) must be run as root."
    exit 1
fi
if [ "$1" = "-v" ] || [ "$1" = "--verbose" ]; then
    v="-v"
    echo "Running $(basename $0) in verbose mode."
    echo
fi

OPENVPN_DIR="/etc/openvpn"
KEY_DIR="$OPENVPN_DIR/keys"
SCRIPT_DIR="$OPENVPN_DIR/scripts"
EASY_DIR="$OPENVPN_DIR/easy-rsa"

# Distribution specific configurations
RPM="/bin/rpm"
DPKG="/usr/bin/dpkg"
if [ -e $RPM ]; then
    echo "$RPM detected. Using CentOS settings."
    echo "Note this script has only been tested for CentOS 6.5 Final 64-bit."
    echo
    PLUGIN_DOWN_ROOT="/usr/lib64/openvpn/plugins/openvpn-plugin-down-root.so"
    GROUP_PRIV="nobody"
    EASY_RSA="/usr/share/easy-rsa/2.0"
    EPEL="http://mirror.ancl.hawaii.edu/linux/epel/6/i386/epel-release-6-8.noarch.rpm"
    EPEL_FILE="/etc/yum.repos.d/epel.repo"

    [ ! -e $EPEL_FILE ] && rpm -U $v -h $EPEL
    yum -y $v install openvpn easy-rsa
    
    # Settings to be able to execute scripts under SELinux Enforcing mode
    selinux_configurations()
    {
        echo "Configuring SELinux to support OpenVPN ..."
        restorecon -R $v $SCRIPT_DIR/
        setsebool openvpn_run_unconfined on
    }
elif [ -e $DPKG ]; then
    echo "$DPKG detected. Using Ubuntu settings."
    echo "Note this script has only been tested for Ubuntu 14.04 LTS Server 64-bit."
    echo
    PLUGIN_DOWN_ROOT="/usr/lib/openvpn/openvpn-plugin-down-root.so"
    GROUP_PRIV="nogroup"
    EASY_RSA="/usr/share/easy-rsa"

    echo "Installing openvpn package ..."
    aptitude -yVR $v install openvpn easy-rsa
else
    echo "Could not find $RPM or ${DPKG}."
fi

mkdir $v $KEY_DIR
chmod $v 700 $KEY_DIR

echo
echo "Copying easy-rsa scripts ..."
mkdir $v $EASY_DIR
cp $v -ar $EASY_RSA/* $EASY_DIR/
chmod $v 700 $EASY_DIR
cp $v -a $EASY_DIR/vars{,.orig}
cd $EASY_DIR
OPENSSL_CNF=$(basename $(find $EASY_DIR -name "openssl-1.?.?.cnf" | sort | tail -1))
[ -f $EASY_DIR/openssl.cnf ] && mv $v $EASY_DIR/openssl.cnf{,.orig}
ln $v -s $OPENSSL_CNF openssl.cnf
cd - >/dev/null

vars()
{
cat << EOF
export EASY_RSA=$EASY_DIR
export OPENSSL="openssl"
export PKCS11TOOL="pkcs11-tool"
export GREP="grep"
export KEY_CONFIG=$EASY_DIR/openssl.cnf
export KEY_DIR=$KEY_DIR
echo NOTE: If you run ./clean-all, I will be doing a rm -rf on $KEY_DIR
export PKCS11_MODULE_PATH="dummy"
export PKCS11_PIN="dummy"
export KEY_SIZE=$KEY_SIZE
export CA_EXPIRE=3650
export KEY_EXPIRE=3650
export KEY_COUNTRY=""
export KEY_PROVINCE=""
export KEY_CITY=""
export KEY_ORG=""
export KEY_EMAIL=""
export KEY_OU=""
export KEY_NAME=$SERVER_NAME
export KEY_CN=$SERVER_NAME
EOF
}

echo
echo "Creating keys ..."

vars > $EASY_DIR/vars

# openssl.cnf fix
sed -i 's/subjectAltName=$ENV::KEY_ALTNAMES/#subjectAltName=$ENV::KEY_ALTNAMES/' $EASY_DIR/openssl.cnf

cd $EASY_DIR
. vars
if [ $? -ne 0 ]; then
    echo "Problems sourcing $EASY_DIR/vars file."
    exit 2
fi

./clean-all
./build-ca                              # Certificate authority
cd $KEY_DIR
mv $v ca.crt ${SERVER_NAME}-CA.crt
mv $v ca.key ${SERVER_NAME}-CA.key
ln $v -s ${SERVER_NAME}-CA.crt ca.crt
ln $v -s ${SERVER_NAME}-CA.key ca.key
cd - >/dev/null
./build-dh
export KEY_NAME="${SERVER_NAME}-00"
./build-key-server ${SERVER_NAME}-00    # Server key pair
export KEY_NAME="${SERVER_NAME}-01"
./build-key ${SERVER_NAME}-01           # First client key pair

server_conf()
{
cat << EOF
dev tun 
tls-server
server $SERVER_NETWORK $SERVER_MASK
port 1194

push "redirect-gateway def1"
up $SCRIPT_DIR/roadwarrior
plugin $PLUGIN_DOWN_ROOT $SCRIPT_DIR/roadwarrior

max-clients 5
client-to-client
duplicate-cn
ifconfig-pool-persist ipp.txt

dh $KEY_DIR/dh${KEY_SIZE}.pem
ca $KEY_DIR/${SERVER_NAME}-CA.crt
cert $KEY_DIR/${SERVER_NAME}-00.crt
key $KEY_DIR/${SERVER_NAME}-00.key

comp-lzo
user nobody
group $GROUP_PRIV

ping 15
ping-restart 45
ping-timer-rem
persist-tun
persist-key

push "ping 15" 
push "ping-restart 45" 
push "persist-tun"
push "persist-key"

verb 3
status /var/log/openvpn-status.log
log /var/log/openvpn.log
log-append /var/log/openvpn.log
EOF
}

roadwarrior_script()
{
cat << EOF
#!/bin/bash
#
# Add or remove masquerade and DNS redirect iptables rules.
# Enables or disables IPv4 forwarding in kernel and iptables.
#
# To use set as 'up' and 'plugin' script in your server .conf:
#
#     up $SCRIPT_DIR/roadwarrior
#     plugin $PLUGIN_DOWN_ROOT $SCRIPT_DIR/roadwarrior
#
iptables="/sbin/iptables"
IP_FORWARD="/proc/sys/net/ipv4/ip_forward"

if ! \$iptables -L -n -t nat | grep -q "OpenVPN:"; then
    \$iptables -t nat -A POSTROUTING -o $OUTBOUND_INT -j MASQUERADE -m comment --comment "OpenVPN: NAT masquerade"
    \$iptables -t nat -A PREROUTING -i tun+ -p udp --dport 53 -j DNAT --to-destination $DNS_IP -m comment --comment "OpenVPN: DNS redirect"
    \$iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT -m comment --comment "OpenVPN: forwarding"
    \$iptables -A FORWARD -s $SERVER_NETWORK/$SERVER_MASK -j ACCEPT -m comment --comment "OpenVPN: forwarding"
    \$iptables -A FORWARD -j REJECT -m comment --comment "OpenVPN: forwarding"
    echo 1 > \$IP_FORWARD
else
    delete_rules()
    {
        table=\$1
        chain=\$2

        # Note lines must be deleted from largest to smallest line number
        lines=\$(\$iptables -L -n --line-number -t \$table | grep "OpenVPN:" | awk '{print $1}' | sort -r)

        for line in \$lines; do 
            \$iptables -D \$chain \$line -t \$table
        done
    }
    delete_rules nat POSTROUTING
    delete_rules nat PREROUTING
    delete_rules filter FORWARD
    echo 0 > \$IP_FORWARD
fi
EOF
}

echo
echo "Creating roadwarrior script in $SCRIPT_DIR ..."
mkdir $v $SCRIPT_DIR
roadwarrior_script > $SCRIPT_DIR/roadwarrior
chmod $v 700 $SCRIPT_DIR $SCRIPT_DIR/roadwarrior

echo "Creating server configuration ..."
server_conf > $OPENVPN_DIR/${SERVER_NAME}.conf

client_conf()
{
cat << EOF
dev tun 
tls-client
proto udp 
pull

<connection>
remote $SERVER_IP 1194
nobind
</connection>

dh /etc/openvpn/keys/dh${KEY_SIZE}.pem
ca /etc/openvpn/keys/${SERVER_NAME}-CA.crt
cert /etc/openvpn/keys/${SERVER_NAME}-01.crt
key /etc/openvpn/keys/${SERVER_NAME}-01.key

comp-lzo
user nobody
group nogroup

verb 3
status /var/log/openvpn-status.log
log /var/log/openvpn.log
log-append /var/log/openvpn.log
EOF
}

echo "Creating client configuration ..."
client_conf > $KEY_DIR/${SERVER_NAME}.conf

tar_client_files()
{
    local n=$1

    echo "Archiving client files to /root/${SERVER_NAME}-${n}.tar.gz ... "
    cd $KEY_DIR
    tar -c $v -z -f /root/${SERVER_NAME}-${n}.tar.gz ${SERVER_NAME}-CA.crt dh${KEY_SIZE}.pem \
        ${SERVER_NAME}-${n}.crt ${SERVER_NAME}-${n}.key ${SERVER_NAME}.conf
    cd - >/dev/null
}

tar_client_files 01
cd /root

[ -f /etc/selinux/config ] && selinux_configurations
service openvpn start

echo
echo "Done."
