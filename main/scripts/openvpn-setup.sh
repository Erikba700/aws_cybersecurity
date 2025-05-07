#!/bin/bash

# Update and install required packages
apt-get update
apt-get install -y wget apt-transport-https

# Add the OpenVPN repository
wget -O - https://swupdate.openvpn.net/repos/openvpn-repo-pkg-key.pub | apt-key add -
echo "deb https://build.openvpn.net/debian/openvpn/stable focal main" > /etc/apt/sources.list.d/openvpn-aptrepo.list

# Update package list and install latest OpenVPN
apt-get update
apt-get install -y openvpn easy-rsa net-tools

# Check OpenVPN version
openvpn --version

# Set up the CA directory
make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa

# Initialize the PKI
./easyrsa init-pki

# Build the CA
./easyrsa --batch build-ca nopass

# Generate server key pair
./easyrsa --batch build-server-full server nopass

# Generate Diffie-Hellman parameters
./easyrsa gen-dh

# Generate ta.key for extra security
openvpn --genkey --secret /etc/openvpn/ta.key

# Copy the files to the OpenVPN directory
cp pki/ca.crt pki/private/server.key pki/issued/server.crt pki/dh.pem /etc/openvpn/

# Create server configuration
cat << EOF > /etc/openvpn/server.conf
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
server 10.20.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt

# Route for all VPCs in 10.0.0.0/8 space, excluding 10.20.0.0/16
push "route 10.0.0.0 255.0.0.0"
push "route 10.20.0.0 255.255.0.0 net_gateway"  # Send 10.20.0.0/16 traffic to the default gateway

push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 10.1.0.2"  # Adjust this to your VPC DNS server
push "dhcp-option DOMAIN your.internal.domain"  # Replace with your internal domain

client-to-client
keepalive 10 120
tls-auth ta.key 0
cipher AES-256-GCM
auth SHA256
persist-key
persist-tun
status openvpn-status.log
verb 3
EOF

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

# Configure NAT
iptables -t nat -A POSTROUTING -s 10.20.0.0/24 -o eth0 -j MASQUERADE

# Save iptables rules without prompting
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
apt-get install -y iptables-persistent

# Start OpenVPN service
systemctl start openvpn@server
systemctl enable openvpn@server

# Set minimal default values for certificate fields
cat << EOF >> /etc/openvpn/easy-rsa/vars
set_var EASYRSA_REQ_CN         "ClientVPN"
set_var EASYRSA_REQ_ORG        "My Organization"
EOF

# Generate client certificate
cd /etc/openvpn/easy-rsa
./easyrsa --batch gen-req client nopass
./easyrsa --batch sign-req client client

# Create directory for client configs
mkdir -p /root/client-configs

# Generate a single, self-contained client configuration file
cat << EOF > /root/client-configs/client.ovpn
client
dev tun
proto udp
remote YOUR_SERVER_IP 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA256
verb 3

<ca>
$(cat /etc/openvpn/easy-rsa/pki/ca.crt)
</ca>

<cert>
$(cat /etc/openvpn/easy-rsa/pki/issued/client.crt)
</cert>

<key>
$(cat /etc/openvpn/easy-rsa/pki/private/client.key)
</key>

<tls-auth>
$(cat /etc/openvpn/ta.key)
</tls-auth>
key-direction 1
EOF

# Secure the client configuration file
chmod 600 /root/client-configs/client.ovpn
