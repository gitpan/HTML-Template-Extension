package HTML::Template::Extension::DOC;

$VERSION 			= "0.11";
sub Version 		{ $VERSION; }

use Carp;
use strict;

my $classname;
my $parentname;

my %fields 	=
			    (
			     );
     
my @fields_req	= qw//;    

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
	# Assign default options
	while (my ($key,$value) = each(%fields)) {
		$self->{$key} = $self->{$key} || $value;
    }
    # Assign options
    while (my ($key,$value) = each(%options)) {
    	$self->{$key} = $value
    }
    # Check required params
    foreach (@fields_req) {
		croak "You must declare '$_' in " . ref($self) . "::new"
				if (!defined $self->{$_});
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
	push @ret,\&_tmpl_doc;
	return \@ret;
}


# funzione filtro per aggiungere il tag </TMPL_DOC> 
# da tenere fintanto che la nostra patch non sia inserita nella 
# distribuzione standard del modulo
sub _tmpl_doc {
        my $template = shift;
        # handle the </TMPL_DOC> tag
        my $re_sh = q{<\s*\/[Tt][Mm][Pp][Ll]_[Dd][Oo][Cc]\s*>};
        my $re_var = q{
          <\s*                           	# first <
          [Tt][Mm][Pp][Ll]_[Dd][Oo][Cc]   	# interesting TMPL_DOC tag only
          \s*>                       		# this is H:T standard tag
          ((?:.*?)                        	# delete alla after here
        } . qq{$re_sh)};
        # String position cursor increment
        my $inc   = 10;
        while ($$template       =~ m{$re_sh}g) {
                my $prematch    = $` . $&;
                my $lpm         = length($prematch);
                my $cur         = $inc * 2 > $lpm ? $lpm : $inc * 2;
                $_              = substr($prematch,-$cur);
                my $amp; my $one;
                until ( m{$re_var}smx                           and
                                $amp = $& and $one=$1           or
                                (
                                        $cur>=$lpm+$inc         and
                                       	die "HTML::Template : </TMPL_DOC> " .
                                       		"without <TMPL_DOC>"
                                )
                        ) {
                                $_ = substr($prematch,-($cur += $inc));
                }
                $amp            = quotemeta($amp);
                $$template      =~ s{$amp\n*}{}sm;
        }
}


1;