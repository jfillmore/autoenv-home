#!/usr/bin/perl

use IO::Socket;
use strict;

if ( scalar(@ARGV) != 2 ) {
 print STDERR "usage: socket_test.pl [host] [port]\n";
 exit 1;
}

my $socket = new IO::Socket::INET ( LocalHost => $ARGV[0], LocalPort => $ARGV[1], Proto => 'tcp', Listen => 1, Reuse => 1, );
if ( ! $socket ) {
 print STDERR "Couldn't create socket: $!\n";
 exit 1;
}
my $new_socket = $socket->accept();
while ( <$new_socket> ) {
 print $_;
}
close( $socket );
