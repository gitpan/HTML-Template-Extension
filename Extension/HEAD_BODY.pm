package HTML::Template::Extension::HEAD_BODY;

$VERSION 			= "0.21";
sub Version 		{ $VERSION; }

use Carp;
use strict;

use HTML::TokeParser;

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
					###if ($$tmpl =~s{^.+?<body([^>'"]*|".*?"|'.*?')+>}{}msi) {
					if ($$tmpl =~s{(^.+?<body(?:[^>'"]*|".*?"|'.*?')+>)}{}msi) {
						bless $self,$classname; 
						###$self->{header} = $&;
						$self->{header} = $1;
						$self->tokenizer_header;
						bless $self,$parentname;
					} else {
						# header doesn't exist
						undef $self->{header};
						undef $self->{tokens};
					}
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

sub tokenizer_header {
	# prende l'header contenuto in $self->{header} e ne estrae i
	# token fondamentali inserendoli in $self->{tokens}
	my $self 		= shift;
	my $header 	= $self->{header};
  $header 		=~m|<head>(.*?)</head>|smi;
	$header			= $1;
	my $p = HTML::TokeParser->new(\$header);
	$self->{tokens} 	= {};
  while (my $token  = $p->get_tag()) {
  	my $tag  = $token->[0];
    my $type = substr($tag,0,1) eq '/' ? 'E' : 'S';
    my $tag_text;
    if ($type eq 'S') {
    	$tag_text = $token->[3];
      my $text = $p->get_text();
      my $struct = [$tag_text,$text,undef];
      push @{$self->{tokens}->{$tag}},$struct;
    } elsif ($type eq 'E') {
      $tag      = substr($tag,1,length($tag)-1);
      $tag_text = $token->[1];
      my $last_idx = scalar @{$self->{tokens}->{$tag}}-1;
      $self->{tokens}->{$tag}->[$last_idx]->[2] = $tag_text;
    }
  }
}


sub header {my $s = shift;return exists($s->{header}) ?  $s->{header} : ''};

sub js_header { return shift->header_js; }

sub header_js {
        # ritorna il codice javascript presente nell'header
        my $self        = shift;
        #bless $self,$classname;
        #$_              = $self->{header};
        my $ret;
        #my $re_init     = q|<\s*script(?:\s*\s+language\s*=\s*['"]?\s*javascript(?:.*?)['"]\s*.*?)?>|;
        #my $re_end  = q|<\s*\/script\s*>|;
        #while (s/$re_init.*?$re_end//msxi) {
        #        $ret .= $&;
        #}
        #bless $self,$parentname;
				my $js_token = $self->{tokens}->{script};
				foreach (@{$js_token}) {
					$ret .= $_->[0] . $_->[1] . $_->[2];
				}
        return $ret;
}

sub header_css {
	# ritorna i css presenti nell'header
	my $self        = shift;
	my $ret;
  my $style_token = $self->{tokens}->{style};
  foreach (@{$style_token}) {
  	$ret .= $_->[0] . $_->[1] . $_->[2];
  }
  return $ret;
}

sub body_attributes {
	# ritorna gli attributi interni al campo body
	my $self 		= shift;
	$_					= $self->{header};
	my $re_init	= q|<\s*body(.*?)>|;
	/$re_init/msxi;
	return $1;
}

sub header_tokens {
	# ritorna un riferimento ad un hash che contiene
	# come chiavi tutti i tag presenti nell'header <HEAD>...</HEAD>
	# ogni elemento dell'hash e' un riferimento ad un array. 
	# Ogni array e' a sua volta un riferimento ad array di tre elementi
	# tag_init - testo contenuto tra il tag e l'eventuale fine tag o successivo tag - eventuale fine tag o undef
	my $self	= shift;
	return $self->{tokens};
}
 


1;
