#!/bin/bash

eth0="#OpenStack management\nauto eth0\niface eth0 inet static\naddress 100.10.10.53\nnetmask 255.255.255.0\n\n"
eth1="#VM Configuration\nauto eth1\niface eth1 inet static\naddress 100.20.20.53\nnetmask 255.255.255.0\n\n"
quantumovs1="sql_connection = mysql://quantumUser:quantumPass@100.10.10.51/quantum"
quantumovs2="tenant_network_type=vlan\nnetwork_vlan_ranges = physnet1:1:4094\nbridge_mappings = physnet1:br-eth1\n"
novaapi="[filter:authtoken]\npaste.filter_factory = keystone.middleware.auth_token:filter_factory\nauth_host = 100.10.10.51\nauth_port = 35357\nauth_protocol = http\nadmin_tenant_name = service\nadmin_user = nova\nadmin_password = service_pass\nsigning_dirname = /tmp/keystone-signing-nova\n"
novacomputeconf="[DEFAULT]\nlibvirt_type=kvm\nlibvirt_ovs_bridge=br-int\nlibvirt_vif_type=ethernet\nlibvirt_vif_driver=nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver\nlibvirt_use_virtio_for_bridges=True"


#apt-get -y update
#apt-get -y upgrade
#apt-get -y dist-upgrade

apt-get -y install ntp

sed -i 's/server ntp.ubuntu.com/server 100.10.10.51/g' /etc/ntp.conf
service ntp restart

apt-get install -y kvm libvirt-bin pm-utils

sed -i '202,207 s/#//g' /etc/libvirt/qemu.conf

virsh net-destroy default
virsh net-undefine default

listen_tls = 0
listen_tcp = 1
auth_tcp = "none"

sed -i '22 s/#//g' /etc/libvirt/libvirtd.conf
sed -i '33 s/#//g' /etc/libvirt/libvirtd.conf
sed -i '146 s/#//g' /etc/libvirt/libvirtd.conf

sed -i '11 s/-d/-d -l/g' /etc/init/libvirt-bin.conf
sed -i '8 s/-d/-d -l/g' /etc/default/libvirt-bin

service libvirt-bin restart
apt-get install -y openvswitch-switch openvswitch-datapath-dkms

ovs-vsctl add-br br-int
ovs-vsctl add-br br-eth1
ovs-vsctl add-port br-eth1 eth1

##Quantum installation
apt-get -y install quantum-plugin-openvswitch-agent

sed -i"" "7c\ $quantumovs1" /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
sed -i"" "25c\ $quantumovs2" /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
sed -i '83 s/#//g' /etc/quantum/quantum.conf
service quantum-plugin-openvswitch-agent restart

##Nova installation
apt-get install nova-compute-kvm
sed -i"" "119,127c\ $novaapi" /etc/nova/api-paste.ini
sed -i"" "1c\ $novacomputeconf" /etc/nova/nova-compute.conf
cp -f novacomputeconf.conf /etc/nova/nova.conf
cd /etc/init.d/; for i in $( ls nova-* ); do sudo service $i restart; done
nova-manage service list

