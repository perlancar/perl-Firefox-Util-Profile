package Firefox::Util::Profile;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{list_firefox_profiles} = {
    v => 1.1,
    summary => 'List available Firefox profiles',
    description => <<'_',

This utility will read ~/.mozilla/firefox/profiles.ini and extracts the list of
profiles.

_
    args => {
        detail => {
            schema => 'bool',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_firefox_profiles {
    require Config::IOD::INI::Reader;
    require Sort::Sub;

    my %args = @_;

    my $ff_dir   = "$ENV{HOME}/.mozilla/firefox";
    my $ini_path = "$ff_dir/profiles.ini";
    unless (-f $ini_path) {
        return [412, "Cannot find $ini_path"];
    }

    my @rows;
    my $hoh = Config::IOD::INI::Reader->new->read_file($ini_path);
    my $naturally = Sort::Sub::get_sorter('naturally');
  SECTION:
    for my $section (sort $naturally keys %$hoh) {
        my $href = $hoh->{$section};
        if ($section =~ /\AProfile/) {
            my $path;
            if (defined($path = $href->{Path})) {
                $path = "$ff_dir/$path" if $href->{IsRelative};
                push @rows, {
                    name => $href->{Name} // $section,
                    path => $path,
                    ini_section => $section,
                };
            } else {
                log_warn "$ini_path: No Path parameter for section $section, section ignored";
                next SECTION;
            }
        }
        # XXX add info: which sections are default in which installation
        # ([Install...] sections)
    }

    unless ($args{detail}) {
        @rows = map { $_->{name} } @rows;
    }

    [200, "OK", \@rows];
}

1;
# ABSTRACT:

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SEE ALSO

Other C<Firefox::Util::*> modules.

L<Chrome::Util::Profile>

L<Vivaldi::Util::Profile>

L<Opera::Util::Profile>

=cut
