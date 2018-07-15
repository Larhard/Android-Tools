#!/usr/bin/env perl

# Move what you can to SD card

use strict;
use warnings;
use v5.20;

use File::Basename qw/dirname/;
use Cwd  qw/abs_path/;
use lib dirname abs_path $0;

use common qw/get_devices get_device_status get_config_ref get_sd_uuid/;

my $config_ref = get_config_ref;

my $uuid = get_sd_uuid;

my @skip_packages = (
    "com.android.chrome",
    "com.android.vending",
    "com.facebook.appmanager",
    "com.facebook.katana",
    "com.facebook.system",
    "com.google.android.apps.docs",
    "com.google.android.apps.docs.editors.docs",
    "com.google.android.apps.docs.editors.sheets",
    "com.google.android.apps.docs.editors.slides",
    "com.google.android.apps.maps",
    "com.google.android.apps.photos",
    "com.google.android.apps.tachyon",
    "com.google.android.gm",
    "com.google.android.gms",
    "com.google.android.googlequicksearchbox",
    "com.google.android.marvin.talkback",
    "com.google.android.music",
    "com.google.android.talk",
    "com.google.android.tts",
    "com.google.android.videos",
    "com.google.android.webview",
    "com.google.android.youtube",
    "com.lge.bnr",
    "com.lge.email",
    "com.lge.exchange",
    "com.lge.launcher3",
    "com.lge.sizechangable.weather",
    "com.lge.sizechangable.weather.platform",
    "com.lge.sizechangable.weather.theme.optimus",
    "com.rsupport.rs.activity.lge.allinone",
);

my @internal_packages = (
    "com.facebook.orca",
    "com.fsck.k9",
    "com.google.android.apps.enterprise.dmagent",
    "com.google.android.calendar",
    "com.google.android.instantapps.supervisor",
    "com.sharp_eu.ste.wifiwidget",
    "com.sophos.smsec",
    "com.touchtype.swiftkey",
    "com.trello",
    "com.wetpalm.ProfileSchedulerPlus",
    "org.pocketworkstation.pckeyboard",
    "pl.mbank",
    "pl.polkomtel.wificallingplus",
    "com.google.android.keep",
    "com.google.android.apps.walletnfcrel",
    "com.bhkapps.shouter",
    "de.dennis_kempf.webwidget",
);

my @packages;

for my $line (`adb shell pm list packages -i -f`) {
    if ($line =~ m/^package:(\S+)=(\S+)\s+installer=(\S+)/) {
        my $apk = $1;
        my $name = $2;
        my $installer = $3;

        my %package = (
            "apk" => $apk,
            "name" => $name,
            "installer" => $installer,
        );

        push @packages, { %package };
    }
}

for my $package (@packages) {
    if ($package->{installer} eq "null") {
        next;
    }

    if ($package->{apk} =~ m/^\/mnt\/asec/) {
        next;
    }

    if ($package->{name} ~~ @skip_packages) {
        next;
    }

    if ($package->{name} ~~ @internal_packages) {
        next;
    }

    print "move $package->{name}\n";
    print "    target: $uuid\n";
    print "    installer: $package->{installer}\n";
    print "    apk: $package->{apk}\n";

    my $out = `adb shell pm move-package "$package->{name}" "$uuid"`;
    $out =~ s/[\n\r]//g;

    print "    result: $out\n";
}

for my $package (@packages) {
    if ($package->{installer} eq "null") {
        next;
    }

    if ($package->{apk} =~ m/^\/data\/app/) {
        next;
    }

    if ($package->{name} ~~ @skip_packages) {
        next;
    }

    if (not $package->{name} ~~ @internal_packages) {
        next;
    }

    print "move $package->{name}\n";
    print "    target: internal\n";
    print "    installer: $package->{installer}\n";
    print "    apk: $package->{apk}\n";

    my $out = `adb shell pm move-package "$package->{name}" internal`;
    $out =~ s/[\n\r]//g;

    print "    result: $out\n";
}
