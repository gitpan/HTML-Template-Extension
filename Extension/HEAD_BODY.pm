package HTML::Template::Extension::HEAD_BODY;

$VERSION 			= "0.11";
sub Version 		{ $VERSION; }

use Carp;
use strict;

my $classname;
my $parentname;

my %fields 	=
			    (
			    	autoDeleteHeader => 0,
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
    bless $self,$parentname;
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
	if ($self->{autoDeleteHeader}) {
		push @ret, sub {
					my $tmpl = shift;
					my $header;
					$$tmpl =~s{^.+?<body([^>'"]*|".*?"|'.*?')+>}{}msi;
					bless $self,$classname; 
					$self->{header} = $&;
					bless $self,$parentname;
					$$tmpl =~ s{</body>.+}{}msi;
				};
	}
	return \@ret;
}

sub autoDeleteHeader { 
	my $s=shift;
	bless $s,$classname; 
	if (@_)  {	
		$s->{autoDeleteHeader}=shift;
		# reload local filter
		bless $s,$parentname;
		$s->reloadFilter;
		$s->{_auto_parse} = 1;
		bless $s,$classname;
	};
	my $ret = $s->{autoDeleteHeader};
	bless $s,$parentname;
	return 
}


sub header {my $s = shift;return exists($s->{header}) ?  $s->{header} : ''};

sub js_header {
        # ritorna il codice javascript presente nell'header
        my $self        = shift;
        bless $self,$classname;
        $_              = $self->{header};
        my $ret;
        my $re_init     = q|<\s*script(?:\s*\s+language\s*=\s*['"]?\s*javascript(?:.*?)['"]\s*.*?)?>|;
        my $re_end  = q|<\s*\/script\s*>|;
        while (s/$re_init.*?$re_end//msxi) {
                $ret .= $&;
        }
        bless $self,$parentname;
        return $ret;
}

1;