#!/bin/bash

credfile=$(export OS_TENANT_NAME=admin\nexport OS_USERNAME=admin\nexport OS_PASSWORD=admin_pass\nexport OS_AUTH_URL='http://192.168.100.51:5000/v2.0/')
eth1="auto eth1\niface eth1 inet static\naddress 192.168.100.51\nnetmask 255.255.255.0\ngateway 192.168.100.1\ndns-nameservers 8.8.8.8\n\n"
eth0="auto eth0\niface eth0 inet static\naddress 100.10.10.51\nnetmask 255.255.255.0\n\n"

#apt-get update
#apt-get upgrade
#apt-get dist-upgrade

sed -i "s/auto eth1/$eth1/g" /etc/network/interfaces
sed -i "s/auto eth0/$eth0/g" /etc/network/interfaces

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
sed -i 's/#net.ipv4.ip_forward=1/sysctl net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl net.ipv4.ip_forward=1
apt-get -y install keystone
mysql -uroot -pskyhigh < sqlkeystone.sql
service keystone restart
keystone-manage db_sync
chmod +x keystone_basic.sh
chmod +x keystone_endpoints_basic.sh
./keystone_basic.sh
./keystone_endpoints_basic.sh
touch creds
echo $credfile > creds
source creds
apt-get -y install curl openssl
curl http://192.168.100.51:35357/v2.0/endpoints -H 'x-auth-token: ADMIN'
apt-get -y install glance
mysql -uroot -pskyhigh < sqlglance.sql
