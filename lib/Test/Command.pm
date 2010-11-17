package Test::Command;

use warnings;
use strict;

=head1 NAME

Test::Command - Test external commands (nearly) as easily as loaded modules.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use base 'Test::Builder::Module';
use IPC::Open3;
use IO::Select;
use Symbol qw(gensym);
use Scalar::Util qw(looks_like_number);
use POSIX qw(:sys_wait_h);

our @EXPORT = qw(
    run
    stdout
    stderr
    rc
    run_ok
    );

=head1 SYNOPSIS

    use Test::Command;

    run('echo', 'has this output'); # only tests that the command can be started, not checking rc
    is(rc,0,'Returned successfully')
    like(stdout,qr/has this output/,'Testing stdout');
    is(length stderr, 0,'No stderr');

=head1 PURPOSE

This test module is intended to simplify testing of external commands.
It does so by running the command under L<IPC::Open3>, closing the stdin
immediately, and reading everything from the command's stdout and stderr.
It then makes the output available to be tested.

It is not (yet?) as feature-rich as L<Test::Cmd>, but I think the
interface to this is much simpler.  Tests also plug directly into the
L<Test::Builder> framework, which plays nice with L<Test::More>.

=head1 EXPORTS

=head2 run

Runs the given command.  It will return when the command is done.

This will also reinitialise all of the states for stdout, stderr, and rc.
If you need to keep the values of a previous run() after a later one,
you will need to store it.  This should be mostly pretty rare.

Counts as one test: whether the IPC::Open3 call to open3 succeeded.
That is not returned in a meaningful way to the user, though.  To check
if that's the case for purposes of SKIPping, rc will be set to -1.

=cut

my ($stdout, $stderr, $rc);
sub run {
    my @cmd = @_;

    # initialise everything each run.
    $rc = -1;
    $stdout = '';
    $stderr = '';

    my ($wtr, $rdr, $err) = map { gensym() } 1..3;
    my $pid = open3($wtr, $rdr, $err, @cmd) or do {
        return Test::Command->builder->ok(0, "Can run '@cmd'");
    };
    Test::Command->builder->ok(1, "Can run '@cmd'");

    my $s = IO::Select->new();
    close $wtr;
    $s->add($rdr);
    $s->add($err);
    
    my %map = (
               fileno($rdr) => \$stdout,
               fileno($err) => \$stderr,
              );
    while (my @ready = $s->can_read())
    {
        for my $fh (@ready)
        {
            my $buffer;
            my $read = sysread($fh, $buffer, 1024);
            if ($read)
            {
                my $fileno = fileno($fh);
                if ($map{$fileno})
                {
                    ${$map{$fileno}} .= $buffer;
                }
            }
            else
            {
                # done.
                $s->remove($fh);
                close $fh;
            }
        }
    }
    waitpid $pid, 0;
    $rc = $?;

    $rc;
}

=head2 stdout

Returns the last run's stdout

=cut

sub stdout() {
    $stdout
}

=head2 stderr

Returns the last run's stderr

=cut

sub stderr() {
    $stderr
}

=head2 rc

Returns the last run's $?

=cut

sub rc() {
    $rc
}

=head2 run_ok

Shortcut for checking that the return from a command is 0.  Will
still set stdout and stderr for further testing.

If the first parameter is an integer 0-255, then that is the expected
return code instead.  Remember: $? has both a return code (0-255) and a
reason for exit embedded.  This function must make the assumption that
you want a "normal" exit only.

Note that this becomes B<two> tests: one that IPC::Open3 could create
the subprocess with the command, and the second is the test of the rc.

=cut

sub run_ok
{
    my $wanted_rc = 0;
    if (looks_like_number($_[0]) &&
        0 <= $_[0] && $_[0] <= 255 &&
        int($_[0]) == $_[0])
    {
        $wanted_rc = shift() << 8;
    }
    run(@_);
    Test::Command->builder->is_eq(rc, $wanted_rc, "Check return from '@_' is $wanted_rc");
}

=head1 AUTHOR

Darin McBride, C<< <dmcbride at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-command at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Command>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Command


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Command>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Command>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Command>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Command/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Darin McBride.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Test::Command
