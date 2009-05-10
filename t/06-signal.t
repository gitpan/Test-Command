#!perl

use Test::Command tests => 7;

use Test::More;

use POSIX;

## determine whether we can run perl or not

system qq($^X -e 1) and BAIL_OUT('error calling perl via system');

signal_is_undef(qq($^X -e "exit 0"));
signal_is_undef(qq($^X -e "exit 1"));
signal_is_undef(qq($^X -e "exit 255"));
signal_is_num(qq($^X -MPOSIX -e "POSIX::raise( &POSIX::SIGTERM )"), &POSIX::SIGTERM );
signal_is_defined(qq($^X -MPOSIX -e "POSIX::raise( &POSIX::SIGTERM )"));

signal_is_undef(qq($^X -e 1));

signal_cmp_ok(qq($^X -MPOSIX -e "POSIX::raise( &POSIX::SIGTERM )"), '==', &POSIX::SIGTERM );
