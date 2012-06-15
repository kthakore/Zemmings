package Avenger::Actor;
use Avenger;

sub actor {
  my %args = @_;
  
  my $base = app->stash->{_avenger}{BASE};

  foreach my $actor_key ( keys %args ) {
      my $actor_class = "$base::$actor_key";
      my $actor; #TODO: Make DSL calling DSL work = $actor_class
  }
 
}

sub import {
    my $class      = shift;
    my %properties = ( ref $_[0] ? %{ $_[0] } : @_ );
    my $caller     = caller;

    no strict 'refs';

    #  *{"${caller}::setup"}   = sub {$self};
}

sub setup {

}

sub draw {

}

sub start {

    return 1;
}

1;
