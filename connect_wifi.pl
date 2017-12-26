#!/usr/bin/env perl

# Connect ADB via wifi

use strict;
use warnings;
use v5.20;

use File::Basename qw/dirname/;
use Cwd  qw/abs_path/;
use lib dirname abs_path $0;

use common qw/get_devices get_device_status get_config_ref/;

my $config_ref = get_config_ref;

my $ip;
my $mask;

my @devices = get_devices;

print "devices found:\n";
for (@devices) {
    print "$_\n";
}
print "\n";

if ($#devices != 0) {
    my $n = $#devices + 1;
    die "invalid number of available devices: $n";
}

my $device = $devices[0];

print "connect to: $device\n";

my $status = get_device_status $device;

if ($status ne "device") {
    die "device $device $status";
}

for (`adb -s "$device" shell ip addr show wlan0`) {
    if (m/^\s*inet\s+([\d.]+)\/(\d+)\s+.*$/) {
        $ip = $1;
        $mask = $2;
    }
}

`adb -s "$device" tcpip "$$config_ref{port}"`;
`adb -s "$device" connect "$ip:$$config_ref{port}"`;
