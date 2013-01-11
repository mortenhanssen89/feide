#!/usr/bin/perl

my $name;
my $commit;

print"file to commit:";
$name = <>;
system("git add $name");

print"commit message:";
$commit = <>;
system("git commit -m '$commit'");

system("git remote add origin https://github.com/mortenhanssen89/feide.git");
system("git pull origin master");
system("git push origin master");
