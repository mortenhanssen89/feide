#!/bin/bash


##Variables
credfile=$(export OS_TENANT_NAME=admin\nexport OS_USERNAME=admin\nexport OS_PASSWORD=admin_pass\nexport OS_AUTH_URL='http://192.168.100.51:5000/v2.0/')
eth1="auto eth1\niface eth1 inet static\naddress 192.168.100.51\nnetmask 255.255.255.0\ngateway 192.168.100.1\ndns-nameservers 8.8.8.8\n\n"
eth0="auto eth0\niface eth0 inet static\naddress 100.10.10.51\nnetmask 255.255.255.0\n\n"
glanceapi="[filter:authtoken]\npaste.filter_factory = keystone.middleware.auth_token:filter_factory\nauth_host = 100.10.10.51\nauth_port = 35357\nauth_protocol = http\nadmin_tenant_name = service\nadmin_user = glance\nadmin_password = service_pass\ndelay_auth_decision = true"
glanceregistry="[filter:authtoken]\npaste.filter_factory = keystone.middleware.auth_token:filter_factory\nauth_host = 100.10.10.51\nauth_port = 35357\nauth_protocol = http\nadmin_tenant_name = service\nadmin_user = glance\nadmin_password = service_pass\npaste.filter_factory = keystone.middelware.auth_token:filter_factory"
glanceapiconf1="sql_connection = mysql://glanceUser:glancePass@100.10.10.51/glance\n"
glanceapiconf2="[paste_deploy]\nflavor = keystone\n"
glanceregistryconf1="sql_connection = mysql://glanceUser:glancePass@100.10.10.51/glance\n"
glanceregistryconf2="[paste_deploy]\nflavor = keystone\n"
quantumini1="sql_connection = mysql://quantumUser:quantumPass@100.10.10.51/quantum"
quantumini2="tenant_network_type=vlan\nnetwork_vlan_ranges = physnet:1:1:4094"
quantumapi="[filter:authtoken]\npaste.filter_factory = keystone.middleware.auth_token:filter_factory\nauth_host = 100.10.10.51\nauth_port = 35357\nauth_protocol = http\nadmin_tenant_name = service\nadmin_user = quantum\nadmin_password = service_pass"
novaapi="[filter:authtoken]\npaste.filter_factory = keystone.middleware.auth_token:filter_factory\nauth_host = 100.10.10.51\nauth_port = 35357\nauth_protocol = http\nadmin_tenant_name = service\nadmin_user = nova\nadmin_password = service_pass\nsigning_dirname = /tmp/keystone-signing-nova\n"
cinderapi="[filter:authtoken]\npaste.filter_factory = keystone.middleware.auth_token:filter_factory\nservice_protocol = http\nservice_host = 192.168.100.51\nservice_port = 5000\nauth_host = 100.10.10.51\nauth_port = 35357\nauth_protocol = http\nadmin_tenant_name = service\nadmin_user = cinder\nadmin_password = service_pass"
cinderconf="[DEFAULT]\nrootwrap_config=/etc/cinder/rootwrap.conf\nsql_connection = mysql://cinderUser:cinderPass@100.10.10.51/cinder\napi_paste_confg = /etc/cinder/api-paste.ini\niscsi_helper=ietadm\nvolume_name_template = volume-%s\nvolume_group = cinder-volumes\nverbose = True\nauth_strategy = keystone\n#osapi_volume_listen_port=5900"

##Updating of the os
#apt-get update
#apt-get upgrade
#apt-get dist-upgrade

##Configuring the network interfaces
sed -i "s/auto eth1/$eth1/g" /etc/network/interfaces
sed -i "s/auto eth0/$eth0/g" /etc/network/interfaces

export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< 'mysql-server mysql-server/root_password password skyhigh'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password skyhigh'

##Installation of mysql and python database
apt-get -y install mysql-server python-mysqldb
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
service mysql restart
apt-get -y install rabbitmq-server
apt-get -y install ntp
sed -i 's/server ntp.ubuntu.com/server ntp.ubuntu.com\nserver 127.127.1.0\nfudge 127.127.1.0 stratum 10/g' /etc/ntp.conf
service ntp restart
apt-get -y install vlan bridge-utils
sed -i 's/#net.ipv4.ip_forward=1/sysctl net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl net.ipv4.ip_forward=1

##Keystone installation
apt-get -y install keystone
mysql -uroot -pskyhigh < sqlkeystone.sql
sed -i 's/connection = sqlite:\/\/\/\/var\/lib\/keystone.db/connection = mysql:\/\/keystoneUser:keystonePass\@100.10.10.51\/keystone/g' /etc/keystone/keystone.conf
service keystone restart
keystone-manage db_sync
chmod +x keystone_basic.sh
chmod +x keystone_endpoints_basic.sh
#./keystone_basic.sh
#./keystone_endpoints_basic.sh
touch creds
echo $credfile > creds
source creds
apt-get -y install curl openssl
curl http://192.168.100.51:35357/v2.0/endpoints -H 'x-auth-token: ADMIN'

##Glance installation
apt-get -y install glance
mysql -uroot -pskyhigh < sqlglance.sql
sed -e "/[filter:authtoken]/,/delay_auth_decision = true/c\ $glanceapi" /etc/glance/glance-api-paste.ini
sed -e "/[filter_authtoken]/,/paste.filter_factory = keystone.middelware.auth_token:filter_factory/c\ $glanceregistry" /etc/glance/glance-registry-paste.ini
sed -i "s/sql_connection = sqlite:\/\/\/\/var\/lib\/glance\/glance.sqlite/$glanceapiconf1/g" /etc/glance/glance-api.conf
sed -i "s/[paste_deply]/$glanceapiconf2/g" /etc/glance/glance-api.conf
sed -i "s/sql_connection = sqlite:\/\/\/\/var\/lib\/glance\/glance.sqlite/$glanceregistryconf1/g" /etc/glance/glance-registry.conf
sed -i "s/[paste_deply]/$glanceregistryconf2/g" /etc/glance/glance-registry.conf
service glance-api restart
service glance-registry restart
glance-manage db_sync
service glance-registry restart
service glance-api restart
#checking glance
mkdir images
cd images
wget https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img
glance image-create --name myFirstImage --is-public true --container-format bare --disk-format qcow2 < cirros-0.3.0-x86_64-disk.img
glance image-list
cd ..

##Quantum installation
apt-get -y install quantum-server quantum-plugin-openvswitch
mysql -uroot -pskyhigh < sqlquantum.sql
sed -i"" "7c\ $quantumini1" /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
sed -i"" "25c\ $quantumini2" /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
sed -i"" "14,21c\ $quantumapi" /etc/quantum/api-paste.ini
service quantum-server restart

##Nova installation
apt-get -y install nova-api nova-cert novnc nova-consoleauth nova-scheduler nova-novncproxy
mysql -uroot -pskyhigh < sqlnova.sql
sed -i"" "119,127c\ $novaapi" /etc/nova/api-paste.ini
mv novacontrollerconf.txt /etc/nova/nova.conf
nova-manage db sync
cd /etc/init.d/
for i in $( ls nova-* ); do sudo service $i restart; done
cd
cd /root/tar/
nova-manage service list

##Cinder installation
apt-get -y install cinder-api cinder-scheduler cinder-volume iscsitarget open-iscsi iscsitarget-dkms
sed -i 's/false/true/g' /etc/default/iscsitarget
service iscsitarget start
service open-iscsi start
mysql -uroot -pskyhigh < sqlcinder.sql
sed -i"" "41,51c\ $cinderapi" /etc/cinder/api-paste.ini
sed -i"" "1,10c\ $cinderconf" /etc/cinder/cinder.conf
cinder-manage db sync
dd if=/dev/zero of=cinder-volumes bs=1 count=0 seek=2G
losetup /dev/loop2 cinder-volumes
fdisk /dev/loop2
echo "n\n"
echo "p\n"
echo "1\n"
echo "\n"
echo "\n"
echo "t\n"
echo "8e\n"
echo "w\n"
pvcreate /dev/loop2
vgcreate cinder-volumes /dev/loop2
########## se hva som må gjøres med cinder volume hvis det blir gjort en reboot ##############
service cinder-volume restart
service cinder-api restart

##Horizon installation
apt-get -y install openstack-dashboard memcached
service apache2 restart
service memcached restart
