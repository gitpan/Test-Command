#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::Command' ) || print "Bail out!
";
}

diag( "Testing Test::Command $Test::Command::VERSION, Perl $], $^X" );
