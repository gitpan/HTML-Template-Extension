package HTML::Template::Extension::IF_TERN;

$VERSION 			= "0.21";
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
	push @ret,\&_if_tern;
	return \@ret;
}


sub _if_tern {
	my $template = shift;
	my $re_var		= q{\%(\S+?)\?(.*?)(\:(.*?))?\%};
	#while ($$template =~ m{$re_var}gsm) {
	#	my $replace;
	#	$replace	= qq{<TMPL_IF NAME="$1">$2};
	#	if (defined $3) {
	#		$replace	.= qq{<TMPL_ELSE>$4</TMPL_IF>};
	#	} else {
	#		$replace	.= q{</TMPL_IF>};
	#	}
	#my $source		= quotemeta($&);
	#$$template 		=~ s{$source}{$replace}sm;
	#}
	$$template =~ s{$re_var}{
		my $replace	= qq{<TMPL_IF NAME="$1">$2};
		if (defined $3) {
			$replace	.= qq{<TMPL_ELSE>$4</TMPL_IF>};
		} else {
			$replace	.= q{</TMPL_IF>};
		}
		$replace;
	}gmse;
	return $$template;
		
}

1;
