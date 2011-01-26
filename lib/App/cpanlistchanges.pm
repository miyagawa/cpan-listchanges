package App::cpanlistchanges;

use strict;
use 5.008_001;
our $VERSION = '0.04';

use Algorithm::Diff;
use CPAN::DistnameInfo;
use Getopt::Long;
use Module::Metadata;
use LWP::UserAgent;
use YAML;
use Try::Tiny;
use Pod::Usage;
use version;

sub new {
    bless {
        all => 0,
    }, shift;
}

sub run {
    my($self, @args) = @_;

    Getopt::Long::GetOptionsFromArray(
        \@args,
        "all|a", \$self->{all},
        "help",  sub { Pod::Usage::pod2usage(0) },
    );

    for my $mod (@args) {
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

    my($from, $to);
    if ($mod =~ s/\@\{?(.+)\}?$//) {
        ($from, $to) = split /\.\./, $1;
        $to = undef if $to eq 'HEAD';
    }

    my $dist = try { YAML::Load( $self->get("http://cpanmetadb.appspot.com/v1.0/package/$mod") ) };
    unless ($dist->{distfile}) {
        warn "Couldn't find a module '$mod'. Skipping.\n";
        return;
    }

    my $meta = Module::Metadata->new_from_module($mod);
    my $info = CPAN::DistnameInfo->new($dist->{distfile});

    $from ||= $meta->{version};
    $to   ||= $info->{version};

    unless ($self->{all} or $from) {
        warn "You don't have the module '$mod' installed locally. Skipping.\n";
        return;
    }

    unless ($self->{all} or $to) {
        warn "Couldn't find the module '$mod' on CPAN MetaDB. Skipping.\n";
        return;
    }

    if (!$self->{all} and version->new($from) >= version->new($to)) {
        warn "You have the latest version of $info->{dist} ($to). Skipping.\n";
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

        if ($self->{all}) {
            print "=== Changes for $info->{dist}\n\n";
            print $get_changes->($to);
            print "\n";
            return;
        }

        my $old_changes = $get_changes->($from);
        my $new_changes = $get_changes->($to);

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
            print "=== Changes between $from and $to for $info->{dist}\n\n";
            print $result;
            print "\n";
        } else {
            warn "Couldn't find changes between $from and $to for $info->{dist}\n";
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

Tokuhiro Matsuno originally wrote the snippet to fetch Changes and
compare with Algorithm::Diff if I remember correctly.

=head1 COPYRIGHT

Copyright 2010- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<cpan-listchanges>

=cut
