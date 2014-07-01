openvpn-roadwarrior
-----
`openvpn-roadwarrior.sh` installs OpenVPN in roadwarrior-style configuration, i.e. all client traffic, including DNS requests, will be routed through this OpenVPN server.

`openvpn-roadwarrior.sh` is setup to install on CentOS 6.5 or later and Ubuntu 14.04 LTS or later systems.

The following tasks are automated in this approximate order:

1. Install `openvpn` and `easy-rsa` packages using either CentOS or Ubuntu settings.
<<<<<<< HEAD
- Note that the `easy-rsa` package was previously bundled with older versions of CentOS and Ubuntu.
=======
..1. Note that the `easy-rsa` package was previously bundled with older versions of CentOS and Ubuntu.
>>>>>>> 3303b3e046255a96854e48f3638037eaf138266f
2. Setup `/etc/openvpn` directory and sub-directories.
3. Generate certificate authority, Diffie-Hellman, server, and (1) client certificate and key pairs.
4. Create server configuration file, up and down roadwarrior script, and client configuraiton file.
5. Configure OpenVPN to work with SELinux if using CentOS.
6. Archive first client certificate and key pair as `/root/openvpn-01.tar.gz`.
