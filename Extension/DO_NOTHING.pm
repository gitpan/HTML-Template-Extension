package HTML::Template::Extension::DO_NOTHING;

$VERSION 			= "0.11";
sub Version 		{ $VERSION; }

use Carp;
use strict;

my $classname;
my $parentname;


sub new
{   
	$classname = shift;
    my $self = shift;
    $parentname = ref($self);
    bless $self,$classname;
    # aggiungo il filtro
    $self->_init_local(@_);
    return $self;
}							

sub _init_local {
	my $self = shift;
	my (%options) = @_;
    # Assign options
    while (my ($key,$value) = each(%options)) {
    	$self->{$key} = $value
    }
	$self->push_filter;								
}

sub push_filter {
	my $self = shift;
	bless $self,$classname;
	push @{$self->{filter}},@{$self->_get_filter()};
	bless $self,$parentname;
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