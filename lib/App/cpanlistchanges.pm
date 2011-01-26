package App::cpanlistchanges;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use Algorithm::Diff;
use CPAN::DistnameInfo;
use Module::Metadata;
use LWP::UserAgent;
use YAML;
use Try::Tiny;
use version;

sub new {
    bless {}, shift;
}

sub run {
    my($self, @modules) = @_;

    for my $mod (@modules) {
        $self->show_changes($mod);
    }
}

sub get {
    my $self = shift;

    $self->{ua} ||= do{
        my $ua = LWP::UserAgent->new(agent => "cpan-listchanges/$VERSION");
        $ua->env_proxy;
        $ua;
    };

    $self->{ua}->get(@_)->content;
}

sub show_changes {
    my($self, $mod) = @_;

    my $dist = try { YAML::Load( $self->get("http://cpanmetadb.appspot.com/v1.0/package/$mod") ) };
    unless ($dist->{distfile}) {
        warn "Couldn't find a module '$mod'. Skipping.\n";
        return;
    }

    my $info = CPAN::DistnameInfo->new($dist->{distfile});
    my $meta = Module::Metadata->new_from_module($mod);

    unless ($meta && $meta->{version}) {
        warn "You don't have the module '$mod' installed locally. Skipping.\n";
        return;
    }

    if (version->new($meta->{version}) >= version->new($info->{version})) {
        warn "You have the latest version of $info->{dist} ($info->{version}). Skipping.\n";
        return;
    }

    # First, get what kind of Changes file it uses - normally just 'Changes'
    # but could be something else. I guess it could be outsourced to FrePAN
    my $html = $self->get("http://search.cpan.org/dist/$info->{dist}");
    $html =~ s/&#(\d+);/chr $1/eg; # search.cpan.org seems to encode all filenames
    if ($html =~ m!<a href="/src/[^"]+">(Change.*?)</a>!i) {
        my $filename = $1;

        my $get_changes = sub {
            my $version = shift;
            $self->get("http://cpansearch.perl.org/src/$info->{cpanid}/$info->{dist}-$version/$filename");
        };

        my $old_changes = $get_changes->($meta->{version});
        my $new_changes = $get_changes->($info->{version});

        my $diff = Algorithm::Diff->new(
            [ split /\n/, $old_changes ],
            [ split /\n/, $new_changes ],
        );
        $diff->Base(1);

        my $result;
        while ($diff->Next()) {
            next if $diff->Same();
            $result .= "$_\n" for $diff->Items(2);
        }

        if ($result) {
            print "=== Changes between $meta->{version} and $info->{version} for $info->{dist}\n\n";
            print $result;
            print "\n";
        } else {
            warn "Couldn't find changes between $meta->{version} and $info->{version} for $info->{dist}\n";
        }
    } else {
        warn "Couldn't find $info->{dist} on CPAN.\n";
    }
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

App::cpanlistchanges - list changes for CPAN modules

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2010- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<cpan-listchanges>

=cut
