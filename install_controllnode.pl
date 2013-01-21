#!/usr/bin/perl
#install_controllnode.pl

#Requirements:
#	Ubuntu 12.10 server
#	Internett connection

#Descrition: This script will install a basic controll node.

my $ifconfeth0 = "iface eth0 inet static\naddress 100.10.10.51\n255.255.255.0\n";
my $ifconfeth1 = "iface eth1 inet dhcp\n";

#system("sudo su");
system("apt-get -y update");
system("apt-get -y upgrade");
system("apt-get -y dist-upgrade");
system("apt-get -y install vim");

open(FILE, "+</etc/network/interfaces") or die "Couldn't open the file! $!\n";
while($line = <FILE>) {
	if($line =~ m/auto lo/) {
		print FILE "$ifconfeth0\n"; 
	}
	
	if($line =~ m/auto eth1/) {
                print FILE "$ifconfeth1"; 
        }
}
close(FILE);

system("export DEBIAN_FRONTEND=noninteractive");
system("debconf-set-selections <<< 'mysql-server mysql-server/root_password password skyhigh'");
system("debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password skyhigh'");
system("apt-get -q -y install mysql-server");
system("apt-get -y install python-mysqldb");
system("sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf");
system("service mysql restart");
system("apt-get -y install rabbitmq-server");
system("apt-get -y install ntp");
system("sed -i 's/server ntp.ubuntu.com/server ntp.ubuntu.com\nserver 127.127.1.0\nfudge 127.127.1.0 stratum 10/g' /etc/ntp.conf");
system("service ntp restart");
system("apt-get -y install vlan bridge-utils");
system("sed -i 's/#net.ipv4.ip_forward=1/sysctl net.ipv4.ip_forward=1/g'");
system("apt-get install -y keystone");

use DBI;
$dbh=DBI->connect('dbi:mysql:' , 'root' , 'skyhigh');
$dbh=do('CREATE DATABASE keystone');
$dbh->quit;

$dbh=DBI->connect('dbi:mysql:keystone' , 'root' , 'skyhigh');
$dbh=do("GRANT ALL ON keystone.* TO 'keystoneUser'\@'%' IDENTIFIED BY 'keystonePass'");
$dbh->quit;

=begin
open(FILE, "keystone_basic.sh") or die "Couldn't open the file!: $!\n";
while($line = <FILE>) {
	if($line =~ m/#/) {
	}
	
	else {
		system("$line");
	}
}
=end
=cut

