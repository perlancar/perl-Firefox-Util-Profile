package Firefox::Util::Profile;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter 'import';
our @EXPORT_OK = qw(list_firefox_profiles);

our %SPEC;

# TODO: allow selecting local Firefox installation

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

$SPEC{get_firefox_profile_dir} = {
    v => 1.1,
    summary => 'Given a Firefox profile name, return its directory',
    description => <<'_',

Return undef if Firefox profile is unknown.

_
    args_as => 'array',
    args => {
        profile => {
            schema => 'firefox::profile_name*',
            cmdline_aliases => {l=>{}},
            req => 1,
            pos => 0,
        },
    },
    result_naked => 1,
};
sub get_firefox_profile_dir {
    my $profile = shift;

    return unless defined $profile;
    my $res = list_firefox_profiles(detail=>1);
    unless ($res->[0] == 200) {
        log_warn "Can't list Firefox profile: $res->[0] - $res->[1]";
        return;
    };

    for (@{ $res->[2] }) {
        return $_->{path} if $_->{name} eq $profile;
    }
    return;
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
