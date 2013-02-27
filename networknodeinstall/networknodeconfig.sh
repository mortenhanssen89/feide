#!/bin/bash

##Var
apipaste="[filter:authtoken]\npaste.filter_factory = keystone.middleware.auth_token:filter_factory\nauth_host = 10.10.10.51\nauth_port = 35357\nauth_protocol = http\nadmin_tenant_name = service\nadmin_user = quantum\nadmin_password = service_pass"
ovs_quantum_plugin_1="sql_connection = mysql://quantumUser:quantumPass@10.10.10.51/quantum"
ovs_quantum_plugin_2="tenant_network_type=vlan\nnetwork_vlan_ranges = physnet1:1:4094\nbridge_mappings = physnet1:br-eth1"
l3_agent="auth_url = http://10.10.10.51:35357/v2.0\nauth_region = RegionOne\nadmin_tenant_name = service\nadmin_user = quantum\nadmin_password = service_pass"

##update system
echo $'\n\n\n###################################################\n############# Installerer update #############\n###################################################\n\n\n'
apt-get -y update
echo $'\n\n\n###################################################\n############# Installerer upgrade #############\n###################################################\n\n\n'
apt-get -y upgrade
echo $'\n\n\n###################################################\n########## Installerer dist-upgrade ###########\n###################################################\n\n\n'
apt-get -y dist-upgrade

##Install and Configure NTP service
apt-get -y install ntp
echo $'\n\n\n###################################################\n############### Installerer ntp ###############\n###################################################\n\n\n'
sed -i 's/server ntp.ubuntu.com/server 10.10.10.51/g' /etc/ntp.conf
service ntp restart
sleep 2

##Configure network
echo $'\n\n\n###################################################\n########### Konfigurerer netverket ############\n###################################################\n\n\n'
apt-get install vlan bridge-utils
#Ip forward
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl net.ipv4.ip_forward=1
#Set network adress
sed -i 's/iface eth0 inet dhcp/iface eth0 inet static\naddress 10.10.10.52\nnetmask 255.255.255.0/g' /etc/network/interfaces
sed -i 's/iface eth1 inet dhcp/iface eth1 inet static\naddress 10.20.20.52\nnetmask 255.255.255.0/g' /etc/network/interfaces
sed -i 's/iface eth2 inet dhcp/iface eth2 inet static\naddress 192.168.100.52\nnetmask 255.255.255.0\ngateway 192.168.100.1\ndns-nameservers 8.8.8.8/g' /etc/network/interfaces

##Install OpenVSwitch
echo $'\n\n\n###################################################\n########## Installerer openvswitch ###########\n###################################################\n\n\n'
apt-get install -y openvswitch-switch openvswitch-datapath-dkms
##Configure OpenVSwitch
#br-int will be used for VM integration
ovs-vsctl add-br br-int
#br-eth1 will be used for VM configuration
ovs-vsctl add-br br-eth1
ovs-vsctl add-port br-eth1 eth1
#br-ex is used to make to VM accessible from the internet
ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex eth2

##Install and Configure Quantum
echo $'\n\n\n###################################################\n#### Installerer og konfigurerer quantum ####\n###################################################\n\n\n'
apt-get -y install quantum-plugin-openvswitch-agent quantum-dhcp-agent quantum-l3-agent
sed -i"" "14,21c\ $apipaste" /etc/quantum/api-paste.ini
sed -i"" "7c\ $ovs_quantum_plugin_1" /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
sed -i"" "25c\ $ovs_quantum_plugin_2" 
sed -i"" "14,18c\ $l3_agent" /etc/quantum/l3_agent.ini
sed -i"" "50c\metadata_ip = 192.168.100.51" /etc/quantum/l3_agent.ini
sed -i"" "53c\metadata_port = 8775" /etc/quantum/l3_agent.ini
sed -i"" "83c\rabbit_host = 10.10.10.51" /etc/quantum/quantum.conf

##Restart services
service quantum-plugin-openvswitch-agent restart
sleep 2
service quantum-dhcp-agent restart
sleep 2
service quantum-l3-agent restart
sleep 2

echo $'\n\n\n###################################################\n##### Ferdig med install av netverknode #####\n###################################################\n\n\n'
