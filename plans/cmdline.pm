#-----------------------------------------------------------------
# App::cmdline
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see the POD.
#
# ABSTRACT: a helper for building command-line applications
# PODNAME: App::cmdline
#-----------------------------------------------------------------
use strict;
use warnings;

package App::cmdline;
use Getopt::Long;
use App::cmdline::Usage;

#-----------------------------------------------------------------
#
#-----------------------------------------------------------------
sub new {
    my ($class, %args) = @_;

    # create an object and fill it from $args
    my $self = bless {}, ref ($class) || $class;
    foreach my $key (keys %args) {
        $self->{$key} = $args {$key};
    }

    # some defaults
    $self->{usage} = '' unless exists $self->{usage};
    $self->{opt_spec} = [] unless exists $self->{opt_spec};
    $self->{config} = [] unless exists $self->{config};

    # done
    return $self;
}

#-----------------------------------------------------------------
# This routine inspects @ARGV and returns the options given and a
# object for generating usage messages.
#
# $args is a hashref with the following keys and values:
#    usage => scalar ... (optional)
#             one line usage string,
#             default: TBD... %c, %o...
#    config => arrayref ... (optional)
#             an array of string passed to the Getopt::Long::Configure
#    opt_spec => arrayref ... (optional but usually given)
#                each element represents a command-line option/argument,
#                each element is an arrayref with:
#                [0] ... Getopt::Long option specification,
#                [1] ... short description (as in Getopt::Long::Descriptive),
#                [2] ... hashref (so far not used)
#
# Return:
#    in scalar context: $opts
#    in array context: ($opts, $usage)
#
#    $opts is a blessed object which has an accessor method for each of
#    the options in 'opt_spec' (using the first-given name, with dashes
#    converted to underscores).
#
#    $usage is a blessed object that can be used to print the usage
#    text.
#
# Notes: this method can be called more than once (then it combines
# opts into a single list).
# -----------------------------------------------------------------
sub describe_options {
    my ($self, $args) = @_;

    # TBD: check types of given arguments
    # TBD: how to combine with already existing args

    if (exists $args->{opt_spec}) {
	my $opts = App::cmdline::Opts->new;
	$opts->add_opts ($args->{opt_spec});
	$self->{opt_spec} = $opts;
    }
    if (exists $args->{usage}) {
	my $usage = App::cmdline::Usage->new;
	$usage->desc ($args->{usage});
	$self->{usage} = $usage;
    }
    if (exists $args->{config}) {
	$self->{config} = $args->{config};
    }

}

1;

package App::cmdline::Usage;

sub desc {
    my ($self, $msg) = @_;
    $self->{msg} = $msg if $msg;
    return $self->{msg};
}

#-----------------------------------------------------------------
#
#-----------------------------------------------------------------
sub new {
    my ($class, %args) = @_;

    my $self = bless {}, ref ($class) || $class;
    foreach my $key (keys %args) {
        $self->{$key} = $args {$key};
    }
    return $self;
}

package App::cmdline::Opts;

sub add_opts {
    my ($self, $opts) = @_;
}

#-----------------------------------------------------------------
#
#-----------------------------------------------------------------
sub new {
    my ($class, %args) = @_;

    my $self = bless {}, ref ($class) || $class;
    foreach my $key (keys %args) {
        $self->{$key} = $args {$key};
    }
    return $self;
}


1;
__END__
sub validate_args {

#  (\%opt, \@args);
# This method is passed a hashref of command line options (as processed
# by Getopt::Long::Descriptive) and an arrayref of leftover
# arguments. It may throw an exception (preferably by calling
# usage_error, below) if they are invalid, or it may do nothing to allow
# processing to continue.  usage_error

}

# ABSTRACT: App::Cmd-specific wrapper for Getopt::Long::Descriptive
sub _process_args {
    my ($class, $args, @params) = @_;
    local @ARGV = @$args;

    require Getopt::Long::Descriptive;
    Getopt::Long::Descriptive->VERSION(0.084);

    my ($opt, $usage) = Getopt::Long::Descriptive::describe_options(@params);

    return (
	$opt,
	[ @ARGV ], # whatever remained
	usage => $usage,
	);
}

sub run {
    my ($self) = @_;

    # We should probably use Class::Default.
    $self = $self->new unless ref $self;

    # prepare the command we're going to run...
    my @argv = $self->prepare_args();
    my ($cmd, $opt, @args) = $self->prepare_command(@argv);

    # ...and then run it
    $self->execute_command($cmd, $opt, @args);
}

sub execute_command {
    my ($self, $cmd, $opt, @args) = @_;

    local our $active_cmd = $cmd;

    $cmd->validate_args($opt, \@args);
    $cmd->execute($opt, \@args);
}

sub usage { $_[0]{usage} };

sub usage_desc {
    # my ($self) = @_; # no point in creating these ops, just to toss $self
    return "%c %o <command>";
}

sub usage_error {
    my ($self, $error) = @_;
    die "Error: $error\nUsage: " . $self->_usage_text;
}

sub _usage_text {
    my ($self) = @_;
    my $text = $self->usage->text;
    $text =~ s/\A(\s+)/!/;
    return $text;
}

1;
__END__

  package YourApp::Cmd;
  use base qw(App::Cmd::Simple);

  sub opt_spec {
    return (
      [ "blortex|X",  "use the blortex algorithm" ],
      [ "recheck|r",  "recheck all results"       ],
    );
  }

  sub validate_args {
    my ($self, $opt, $args) = @_;

    # no args allowed but options!
    $self->usage_error("No args allowed") if @$args;
  }

  sub execute {
    my ($self, $opt, $args) = @_;

    my $result = $opt->{blortex} ? blortex() : blort();

    recheck($result) if $opt->{recheck};

    print $result;
  }
