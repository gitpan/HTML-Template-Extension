package HTML::Template::Extension::DO_NOTHING;

$VERSION 			= "0.22";
sub Version 		{ $VERSION; }

use Carp;
use strict;

my %fields_parent   =
                (
                 );

sub init {
    my $self = shift;
    while (my ($key,$val) = each(%fields_parent)) {
        $self->{$key} = $self->{$key} || $val;
    }
	&push_filter($self);
}

sub push_filter {
    my $self = shift;
    push @{$self->{filter}},@{_get_filter($self)};
}
sub _get_filter {
	my $self = shift;
	my @ret ;
	push @ret,\&_do_nothing;
	return \@ret;
}


sub _do_nothing {
       my $template = shift;
       $$template = $$template
}

1;
