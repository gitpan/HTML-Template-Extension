package HTML::Template::Extension::SLASH_VAR;

$VERSION 			= "0.21";
sub Version 		{ $VERSION; }

use Carp;
use strict;

my $classname;
my $parentname;

my %fields 	=
			    (
			    	ecp_compatibility_mode => 0,
			     );
     
my @fields_req	= qw//;    

my $re_var = q{
  ((<\s*                           # first <
  [Tt][Mm][Pp][Ll]_[Vv][Aa][Rr]   # interesting TMPL_VAR tag only
  (?:.*?)>)                       # this is H:T standard tag
  ((?:.*?)                        # delete alla after here
  <\s*\/                          # if there is the </TMPL_VAR> tag
  [Tt][Mm][Pp][Ll]_[Vv][Aa][Rr]
  \s*>))
};

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
	# Sorry for this :->. I've an e-commerce project called ecp that
	# use a modified vanguard compatibility mode %%...%% 
	# This disable vanguard_compatibility_mode
	if ($self->{ecp_compatibility_mode}) {
		push @ret,\&_ecp_vanguard_syntax ;
		$self->{options}->{vanguard_compatibility_mode}=0;
	}
	push @ret,\&_slash_var;
	return \@ret;
}


# funzione filtro per aggiungere il tag </TMPL_VAR> 
# da tenere fintanto che la nostra patch non sia inserita nella 
# distribuzione standard del modulo
sub _slash_var {
        my $template = shift;
        # handle the </TMPL_VAR> tag
###        my $re_sh = q{<\s*\/[Tt][Mm][Pp][Ll]_[Vv][Aa][Rr]\s*>};
###        # String position cursor increment
###        my $inc   = 15;
###        while ($$template       =~ m{$re_sh}g) {
###                my $prematch    = $` . $&;
###                my $lpm         = length($prematch);
###                my $cur         = $inc * 2 > $lpm ? $lpm : $inc * 2;
###                $_              = substr($prematch,-$cur);
###                my $amp; my $one;
###                until ( m{$re_var}smx                           and
###                                $amp = $& and $one=$1           or
###                                (
###                                        $cur>=$lpm+$inc         and
###                                       	die "HTML::Template : </TMPL_VAR> " .
###                                       		"without <TMPL_VAR>"
###                                )
###                        ) {
###                                $_ = substr($prematch,-($cur += $inc));
###                }
###                $amp            = quotemeta($amp);
###                $$template      =~ s{$amp}{$one}sm;
###        }
	####$$template =~s{$re_var}{$1}xsg;
	while ($$template =~/(?=$re_var)/sgx) {
        my $two = $2;
        if ($3 !~/(?:$re_var)/sx) {
                $$template =~s{\Q$1}{$two}s;
        }
    }
    return $$template;
}

sub _ecp_vanguard_syntax {
	my $template 	= shift;
    if ($$template =~/%%([-\w\/\.+]+)%%/) {
    	$$template =~ s/%%([-\w\/\.+]+)%%/<TMPL_VAR NAME=$1>/g;
    }
}

1;
