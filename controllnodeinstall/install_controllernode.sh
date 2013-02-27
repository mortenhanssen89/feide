#!/bin/bash


##Variables
eth0="auto eth0\niface eth1 inet static\naddress 128.39.141.222\nnetmask 255.255.254.0\ngateway 128.39.140.1\ndns-nameservers 8.8.8.8\n\n"
eth1="auto eth1\niface eth0 inet static\naddress 10.10.10.51\nnetmask 255.255.255.0\n\n"
keystoneconf="connection = mysql://keystoneUser:keystonePass@10.10.10.51/keystone"
glanceapi="[filter:authtoken]\npaste.filter_factory = keystone.middleware.auth_token:filter_factory\nauth_host = 10.10.10.51\nauth_port = 35357\nauth_protocol = http\nadmin_tenant_name = service\nadmin_user = glance\nadmin_password = service_pass"
glanceregistry="[filter:authtoken]\npaste.filter_factory = keystone.middleware.auth_token:filter_factory\nauth_host = 10.10.10.51\nauth_port = 35357\nauth_protocol = http\nadmin_tenant_name = service\nadmin_user = glance\nadmin_password = service_pass\npaste.filter_factory = keystone.middelware.auth_token:filter_factory"
glanceapiconf1="sql_connection = mysql://glanceUser:glancePass@10.10.10.51/glance"
glanceapiconf2="flavor = keystone"
glanceregistryconf1="sql_connection = mysql://glanceUser:glancePass@10.10.10.51/glance"
glanceregistryconf2="flavor = keystone"
quantumini1="sql_connection = mysql://quantumUser:quantumPass@10.10.10.51/quantum"
quantumini2="tenant_network_type = vlan"
quantumini3="network_vlan_ranges = physnet:1:1:4094"
quantumapi="[filter:authtoken]\npaste.filter_factory = keystone.middleware.auth_token:filter_factory\nauth_host = 10.10.10.51\nauth_port = 35357\nauth_protocol = http\nadmin_tenant_name = service\nadmin_user = quantum\nadmin_password = service_pass"
novaapi="[filter:authtoken]\npaste.filter_factory = keystone.middleware.auth_token:filter_factory\nauth_host = 10.10.10.51\nauth_port = 35357\nauth_protocol = http\nadmin_tenant_name = service\nadmin_user = nova\nadmin_password = service_pass\nsigning_dirname = /tmp/keystone-signing-nova"
cinderapi="[filter:authtoken]\npaste.filter_factory = keystone.middleware.auth_token:filter_factory\nservice_protocol = http\nservice_host = 128.39.141.222\nservice_port = 5000\nauth_host = 10.10.10.51\nauth_port = 35357\nauth_protocol = http\nadmin_tenant_name = service\nadmin_user = cinder\nadmin_password = service_pass"
cinderconf="[DEFAULT]\nrootwrap_config=/etc/cinder/rootwrap.conf\nsql_connection = mysql://cinderUser:cinderPass@10.10.10.51/cinder\napi_paste_confg = /etc/cinder/api-paste.ini\niscsi_helper=ietadm\nvolume_name_template = volume-%s\nvolume_group = cinder-volumes\nverbose = True\nauth_strategy = keystone\n#osapi_volume_listen_port=5900"

##Updating of the os
echo $'\n\n\n###################################################\n### Kjører update, upgrade og dist-upgrade ###\n###################################################\n\n\n'
apt-get -y update
apt-get -y upgrade
apt-get -y dist-upgrade

##Configuring the network interfaces
#sed -i "s/auto eth1/$eth1/g" /etc/network/interfaces
#sed -i "s/auto eth0/$eth0/g" /etc/network/interfaces

##Installation of mysql and python database
echo $'\n\n\n###################################################\n##########Installerer mysql og python-sqldb##########\n###################################################\n\n\n'
export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< 'mysql-server mysql-server/root_password password skyhigh'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password skyhigh'
apt-get -y install mysql-server python-mysqldb
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
service mysql restart
apt-get -y install rabbitmq-server
apt-get -y install ntp
sed -i 's/server ntp.ubuntu.com/server ntp.ubuntu.com\nserver 127.127.1.0\nfudge 127.127.1.0 stratum 10/g' /etc/ntp.conf
service ntp restart
apt-get -y install vlan bridge-utils
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl net.ipv4.ip_forward=1

##Keystone installation
echo $'\n\n\n###################################################\n### Installerer Keystone og lager keystone database ###\n###################################################\n\n\n'
apt-get -y install keystone
mysql -uroot -pskyhigh < sqlkeystone.sql
sed -i "58 c\\$keystoneconf" /etc/keystone/keystone.conf
service keystone restart
keystone-manage db_sync
sleep 5
echo $'\n\n\n###################################################\n### keysone_basic.sh og keystone_endpoints_basic.sh ###\n###################################################\n\n\n'
chmod +x keystone_basic.sh
chmod +x keystone_endpoints_basic.sh
./keystone_basic.sh
./keystone_endpoints_basic.sh
source creds
apt-get -y install curl openssl
curl http://128.39.141.222:35357/v2.0/endpoints -H 'x-auth-token: ADMIN'

##Glance installation
echo $'\n\n\n###################################################\n### Installerer glance og redigerer filer til glance ###\n###################################################\n\n\n'
apt-get -y install glance
mysql -uroot -pskyhigh < sqlglance.sql
sed -i "55i\\$glanceapi" /etc/glance/glance-api-paste.ini
sed -i '63,70d' /etc/glance/glance-api-paste.ini
sed -i "18i\\$glanceregistry" /etc/glance/glance-registry-paste.ini
sed -i '26,33d' /etc/glance/glance-registry-paste.ini
sed -i "49c\\$glanceapiconf1" /etc/glance/glance-api.conf
sed -i "325c\\$glanceapiconf2" /etc/glance/glance-api.conf
sed -i "28c\\$glanceregistryconf1" /etc/glance/glance-registry.conf
sed -i "86c\\$glanceregistryconf2" /etc/glance/glance-registry.conf
service glance-api restart
sleep 2
service glance-registry restart
sleep 2
glance-manage db_sync
sleep 5
service glance-registry restart
sleep 2
service glance-api restart
sleep 2

echo $'\n\n\n###################################################\n########## Ferdig med glance installasjonen ##########\n###################################################\n\n\n'
#checking glance
mkdir images
cd images
wget https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img
glance image-create --name myFirstImage --is-public true --container-format bare --disk-format qcow2 < cirros-0.3.0-x86_64-disk.img
echo $'\n\n\n###################################################\n########### Liste over imagene til glance ###########\n###################################################\n\n\n'
glance image-list
sleep 5
cd ..

##Quantum installation
echo $'\n\n\n###################################################\n####### Installerer quantum og lager databasen #######\n###################################################\n\n\n'
apt-get -y install quantum-server quantum-plugin-openvswitch
mysql -uroot -pskyhigh < sqlquantum.sql
sed -i "7c\\$quantumini1" /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
sed -i "24c\\$quantumini2" /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
sed -i "36c\\$quantumini3" /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
sed -i "14i\\$quantumapi" /etc/quantum/api-paste.ini
sed -i '22,29d' /etc/quantum/api-paste.ini
service quantum-server restart
echo $'\n\n\n###################################################\n################ Ferdig med quantum #################\n###################################################\n\n\n'

##Nova installation
echo $'\n\n\n###################################################\n######## Installerer nova og lager databasen ########\n###################################################\n\n\n'
apt-get -y install nova-api nova-cert novnc nova-consoleauth nova-scheduler nova-novncproxy
mysql -uroot -pskyhigh < sqlnova.sql
sed -i "119i\\$novaapi" /etc/nova/api-paste.ini
sed -i '128,136d' /etc/nova/api-paste.ini
mv /etc/nova/nova.conf /etc/nova/nova.conf.orig
mv novacontrollerconf.conf /etc/nova/nova.conf
nova-manage db sync
sleep 5
cd /etc/init.d/
for i in $( ls nova-* ); do sudo service $i restart; done
cd /home/skyhigh/

echo $'\n\n\n###################################################\n######## Liste over service-listen til nova #########\n###################################################\n\n\n'
nova-manage service list
sleep 5
echo $'\n\n\n###################################################\n################## Ferdig med nova ##################\n###################################################\n\n\n'

##Cinder installation
echo $'\n\n\n###################################################\n####### Installerer cinder og lager databasen #######\n###################################################\n\n\n'
apt-get -y install cinder-api cinder-scheduler cinder-volume iscsitarget open-iscsi iscsitarget-dkms
sed -i 's/false/true/g' /etc/default/iscsitarget
service iscsitarget start
sleep 2
service open-iscsi start
sleep 2
mysql -uroot -pskyhigh < sqlcinder.sql
sed -i "41i\\$cinderapi" /etc/cinder/api-paste.ini
sed -i '52,62d' /etc/cinder/api-paste.ini
sed -i "1i\\$cinderconf" /etc/cinder/cinder.conf
sed -i '11,20d' /etc/cinder/cinder.conf
cinder-manage db sync
sleep 5
echo $'\n\n\n###################################################\n################# Ferdig med cinder #################\n###################################################\n\n\n'

echo $'\n\n\n###################################################\n######### Lager fdisk med rette instillinger ########\n###################################################\n\n\n'
dd if=/dev/zero of=cinder-volumes bs=1 count=0 seek=2G
losetup /dev/loop2 cinder-volumes
fdisk /dev/loop2 << EOF
n
p
1
\n
\n
t
8e
w
\n
EOF

pvcreate /dev/loop2
vgcreate cinder-volumes /dev/loop2
########## se hva som må gjøres med cinder volume hvis det blir gjort en reboot ##############
service cinder-volume restart
sleep 2
service cinder-api restart
sleep 2

##Horizon installation
echo $'\n\n\n###################################################\n################ Installerer horizon ################\n###################################################\n\n\n'
apt-get -y install openstack-dashboard memcached
service apache2 restart
sleep 2
service memcached restart
sleep 2

##Reboot av serveren
echo $'\n\n\n###################################################\n################# Restarter serveren ################\n###################################################\n\n\n'
reboot -h now
