package HTML::Template::Extension::CSTART;

$VERSION 			= "0.11";
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
	# use a CSTART modified syntax using html comment
	push @ret,\&_ecp_cstart if ($self->{ecp_compatibility_mode});
	# Standard CSTART syntax
	push @ret,\&_cstart;
	return \@ret;
}


# funzione filtro per aggiungere il tag <TMPL_CSTART> 
# da tenere fintanto che la nostra patch non sia inserita nella 
# distribuzione standard del modulo
sub _cstart {
        my $template = shift;
        my $re_sh = q{<\s*\/[Tt][Mm][Pp][Ll]_[Cc][Ss][Tt][Aa][Rr][Tt]\s*>};
        my $re_var = q{
          <\s*                           	
          [Tt][Mm][Pp][Ll]_[Cc][Ss][Tt][Aa][Rr][Tt]   	
          \s*>                       		
          ((.*?)                        	
        } . qq{$re_sh)};
        # String position cursor increment
        my $inc   = 15;
        my $ret;
        while ($$template       =~ m{$re_sh}g) {
                my $prematch    = $` . $&;
                my $lpm         = length($prematch);
                my $cur         = $inc * 2 > $lpm ? $lpm : $inc * 2;
                $_              = substr($prematch,-$cur);
                my $amp; my $one;
                until ( m{$re_var}smx                           and
                                $amp = $& and $one=$2           or
                                (
                                        $cur>=$lpm+$inc         and
                                       	die "HTML::Template : </TMPL_CSTART> " .
                                       		"without <TMPL_CSTART>"
                                )
                        ) {
                                $_ = substr($prematch,-($cur += $inc));
                }
                $amp            = quotemeta($amp);
                #$$template      =~ s{$amp}{$one}sm;
                $ret .= $one;
        }
        $$template = $ret;
}

sub _ecp_cstart {
   	my $template 	= shift;
    my $brem		='<!' . '--';
    my $eend		='--' . '>';
    my $start 		= qq=$brem\\s*[Cc][Ss][Tt][Aa][Rr][Tt]\\s*$eend=;
    my $end 		= qq=$brem\\s*[Cc][Ee][Nn][Dd]\\s*$eend=;
    if ($$template =~/$end/) {
    	$$template =~s|$start|<TMPL_CSTART>|g;
    	$$template =~s|$end|</TMPL_CSTART>|g;
    }
}


1;