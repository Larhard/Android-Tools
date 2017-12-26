package common;

use strict;
use warnings;
use v5.20;

use Exporter qw/import/;

our @EXPORT_OK = qw/get_devices get_device_status get_config_ref get_sd_uuid/;

use Config::Simple;
use File::Copy;

sub get_devices_info(;) {
    my %result;
    for (`adb devices`) {
        if (m/List of devices attached/) {
            next;
        }

        if (m/^(\S+)\s+(\S+)$/) {
            my $name = $1;
            my $status = $2;

            $result{$name} = $status;
        }
    }
    return %result;
}

sub get_devices(;) {
    my %devices_info = get_devices_info;
    my @result = keys %devices_info;
    return @result;
}

sub get_device_status($;) {
    my $name = $_[0];
    my %devices_info = get_devices_info;
    return $devices_info{$name};
}

sub get_config_ref(;) {
    if (not -e "config.ini") {
        copy "config.ini.default", "config.ini";
    }

    tie my %config, "Config::Simple", "config.ini" or die Config::Simple->error();
    tied(%config)->autosave(1);

    return \%config;
}

sub get_sd_uuid(;) {
    my $result;

    for (`adb shell ls /storage`) {
        s/[\r\n]//g;

        if (m/^emulated$/) {
            next;
        }

        if (m/^sdcard0$/) {
            next;
        }

        if (m/^self$/) {
            next;
        }

        if (defined $result) {
            die "multiple sd cards detected";
        }
        $result = $_;
    }

    return $result;
}

1;
