package HTML::Template::Extension;

$VERSION 			= "0.23";
sub Version 		{ $VERSION; }

use HTML::Template;
@HTML::Template::Extension::ISA = qw(HTML::Template);



use Carp;
use Data::Dumper;
use FileHandle;
use vars qw($DEBUG $DEBUG_FILE_PATH);
use strict;

$DEBUG 				= 0;
$DEBUG_FILE_PATH	= '/tmp/HTML-Template-Extension.debug.txt';

my %fields 	=
			    (
			    	plugins => [],
			    	filename => undef,
			    	scalarref=>undef,
			    	arrayref=>undef,
			    	filehandle=>undef,
			     );
     
my @fields_req	= qw//;
my $DEBUG_FH;     

sub new
{   
	my $proto = shift;
    my $class = ref($proto) || $proto;
    # aggiungo il filtro
    my $self  = {};
    # I like %TAG_NAME% syntax
    push @_,('vanguard_compatibility_mode' => 1);
    # no error if a tag present in html was not set
    push @_,('die_on_bad_params' => 0);
    # enable loop variable items
    push @_,('loop_context_vars' => 1);
	# if don't exists neither filename, nor filehandle, nor scalarref,
	# nor arrayref, add an empty scalarref to correct init HTML::Template
	my %check = @_;
	push @_,('scalarref' => \'') unless (	exists $check{'filename'}   || 
											exists $check{'filehandle'} ||
											exists $check{'scalarref'}  || 
											exists $check{'arrayref'});
	bless $self,$class;
    $self->_init_local(@_);
	$self->_loadDynamicModule;
	push @_,('filter' => $self->{filter});
    my $htmpl = $class->HTML::Template::new(@_);
    foreach (keys(%{$htmpl})) {
    	$self->{$_} = $htmpl->{$_};
    }
    bless $self,$class;
#    $self->{filename}=$self->{options}->{filename};
#    $self->{scalarref}=$self->{options}->{scalarref};
#    $self->{arrayref}=$self->{options}->{arrayref};
#    $self->{filehandle}=$self->{options}->{filehandle};
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
	$self->{DEBUG_FH} = new FileHandle ">>$DEBUG_FILE_PATH" if ($DEBUG);
	$self->push_filter;										
}

sub output {
	# redefine standard output function
	my $self = shift;
	my %args = @_;
	if ($self->{_auto_parse}) {
		$self->reloadFile();
	}
	if (exists $args{as}) {
		# delete old params settings
		$self->SUPER::clear_params();
		my %as = %{$args{as}};
		foreach (keys %as) {
			$self->SUPER::param($_ => $as{$_});
		}
	}
	my $output = $self->SUPER::output(%args);
	print {$self->{'DEBUG_FH'}} Data::Dumper::Dumper($self) if ($DEBUG);
	return $output;
}

sub html {
	my $self 		 = shift;
	my %args 		 = (defined $_[0]) ? %{$_[0]} : ();
	$self->{filename}= $_[1] if (defined $_[1]);
	if ( defined $self->{filename} 
			&& (
				!defined $self->{options}->{filename}
					||	$self->{filename} ne $self->{options}->{filename} 
				)
			|| $self->{_auto_parse}
		) {
		$self->reloadFile();
	}
	return $self->output('as' => \%args);
}

sub filename { 
	my $s=shift;
	if (@_)  {
		my $new_file = shift;
		if ($s->{filename} ne $new_file) {
			$s->{filename} = $new_file;
			# reload local file
			$s->{_auto_parse} = 1;	
			# remove other text storage
			delete($s->{scalarref});
			delete($s->{arrayref});
			delete($s->{filehandle});
		}
	};
	return $s->{filename};
}

sub scalarref { 
	my $s=shift;
	if (@_)  {
		$s->{scalarref} = shift;
		# reload local file
		$s->{_auto_parse} = 1;	
		delete($s->{filename});
		delete($s->{options}->{filename});
		delete($s->{arrayref});
		delete($s->{filehandle});
	};
	# remove other text storage
	return $s->{scalarref};
}

sub arrayref { 
	my $s=shift;
	if (@_)  {
		$s->{arrayref} = shift;
		# reload local file
		$s->{_auto_parse} = 1;	
		# remove other text storage
		delete($s->{scalarref});
		delete($s->{filename});
		delete($s->{options}->{filename});
		delete($s->{filehandle});
	};
	return $s->{arrayref};
}

sub filehandle { 
	my $s=shift;
	if (@_)  {
		$s->{filehandle} = shift;
		# reload local file
		$s->{_auto_parse} = 1;	
		# remove other text storage
		delete($s->{scalarref});
		delete($s->{arrayref});
		delete($s->{filename});
		delete($s->{options}->{filename});
	};
	
	return $s->{filehandle};
}

sub reloadFile {
	my $self = shift;
	$self->{_auto_parse} = 0;
	if ( defined $self->{filename} 
			&& ( !defined $self->{options}->{filename}
					|| $self->{filename} ne $self->{options}->{filename}
				)
		) {
		$self->{options}->{filename} = $self->{filename};
		my $filepath = $self->_find_file($self->{filename});  
		$self->{options}->{filepath} = $self->{filename};
	} elsif (exists($self->{scalarref})) {
    	$self->{options}->{scalarref} = $self->{scalarref};
	} elsif (exists($self->{arrayref})) {
		$self->{options}->{arrayref}=$self->{arrayref};
	} elsif (exists($self->{filehandle})) {
		$self->{options}->{filehandle} = $self->{filehandle};
	}
	$self->{options}->{filter}= $self->{filter};
	$self->_init_template();
	# local caching params
	my %params;
	my @parname = $self->param();
	foreach (@parname) {
		$params{$_} = $self->param($_);
	}
	$self->_parse();
	# reassign params
	foreach (keys(%params)) {
		$self->param($_=> $params{$_});
	}
	# now that we have a full init, cache the structures if cacheing is
	# on.  shared cache is already cool.
	if($self->{options}->{file_cache}){
	$self->_commit_to_file_cache();
	}
	$self->_commit_to_cache() if (($self->{options}->{cache}
	                            and not $self->{options}->{shared_cache}
	                            and not $self->{options}->{file_cache}) or
	                            ($self->{options}->{double_cache}) or
	                            ($self->{options}->{double_file_cache}));
}


sub reloadFilter {
	my $self = shift;
	undef $self->{filter} ;
	no strict "refs";
	# plugin priority filter
	{
		foreach (@{$self->{plugins}}) {
			my $module = "HTML::Template::Extension::$_";
        	&{"${module}::push_filter"}($self);
	    }
    }
    #$self->push_filter;
}

sub push_filter {
	my $self = shift;
}

sub _loadDynamicModule {
	my $self = shift;
	{
		no strict "vars";
		no strict "refs";
		foreach (@{$self->{plugins}}) {
				my $module = "HTML::Template::Extension::$_";
	    		my $module_string = $module;
	    		$module_string =~s/::/\//g;
	    		require $module_string . ".pm";
	    		#import $module_string . ".pm";
				&{$module . "::init"}($self);
	    }
	}
}


sub filter { my $s=shift; return @_ ? ($s->{filter}=shift) : $s->{filter} }

sub plugin_add { 
	my $s=shift; 
	if (@_)  {
		push @{$s->{plugins}},shift;
		# reload modules
		$s->_loadDynamicModule;
		# reload local filter
		$s->reloadFilter;
		$s->{_auto_parse} = 1;
	};
	return $s->{plugins}
}

sub plugins_clear { 
	my $s = shift;
	undef $s->{plugins};
	return $s->{plugins};
}

sub DESTROY {
}

sub AUTOLOAD {
	my $self = shift;
	my @procs = split(/::/,$HTML::Template::Extension::AUTOLOAD);
	return if (scalar(@procs)<3);
	my $proc = $procs[-1];
	my $value;
	no strict "refs";
	foreach (@{$self->{plugins}}) {
		my $module = "HTML::Template::Extension::$_";
		my $ret;
		$ret=  eval { return &{"${module}::$proc"}($self,@_) };
		if (!$@) { return  $ret };
	};
}




1;
