#!/usr/bin/perl
#install_controllnode.pl

#Requirements:
#	Ubuntu 12.10 server
#	Internett connection

#Descrition: This script will install a basic controll node.

use strict;
use warnings;
use DBI;

my $system1 = "system1.txt";
my $system2 = "system2.txt";
my $line;

sub readfile {
	open(FILE, "< $_[0]") or die "Couldn't open the file! $_[0]\n";
	while($line = <FILE>) {
		system($line);
	}
	close(FILE);
};

sub networkfile() {	
	my $ifconfeth0 = "iface eth0 inet static\naddress 100.10.10.51\n255.255.255.0\n";
	my $ifconfeth1 = "iface eth1 inet dhcp\n";	

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
};

sub sql() {
	my $dbh;
	my $statement;
	my $dbuser = "root";
	my $dbpass = "skyhigh";
	my $connectmysql = "dbi:mysql:"; 
	my $connectkeystone = "dbi:mysql:keystone";	
	my $cdk = "CREATE DATABASE keystone";
	my $gak = "GRANT ALL ON keystone.* TO 'keystoneUser'\@'%' IDENTIFIED BY 'keystonePass'";

	$dbh=DBI->connect($connectmysql, $dbuser, $dbpass);
	$statement = $dbh->prepare($cdk);
	$statement->execute();
	$dbh->disconnect();
	
	$dbh=DBI->connect($connectkeystone, $dbuser, $dbpass);
	$statement = $dbh->prepare($gak);
	$statement->execute();
	$dbh->disconnect();
};

sub makecredfile() {
	my $textinfile = "export OS_TENANT_NAME=admin\nexport OS_USERNAME=admin\nexport OS_PASSWORD=admin_pass\nexport OS_AUTH_URL=\"http://192.168.100.51:5000/v2.0/\"";

	system("touch creds");
	open(FILE, ">creds") or die "Couldn't write to file! $!\n";
	print FILE  $textinfile;
	close(FILE);
	system("source creds");
};



#readfile($system1);
networkfile();
readfile($system2);
sql();
#Modify the HOST_IP and HOST_IP_EXT variables before executing the scripts
#system("chmod +x keystone_basic.sh");
#system("./keystone_basic.sh");
#system("chmod +x keystone_endpoints_basic.sh");
#system("./keystone_endpoints_basic.sh");
makecredfile();
