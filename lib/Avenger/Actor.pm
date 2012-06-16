package Avenger::Actor;
use Avenger;

sub actor {
  my %args = @_;
  
  my $base = app->stash->{_avenger}{BASE};

  foreach my $actor_key ( keys %args ) {
      my $actor_class = "$base::$actor_key";
      my $actor = new( $actor_class,  $args{$actor_key} ); 
      #TODO: Make DSL calling DSL work = $actor_class
  }
 
}


sub new {
    my $class = shift; 
    my %args = @_;
    my $body_hr = delete $args{body};

       $body_hr = ${class}->pre_setup( $body_hr );
    my $body = world->create_body( $body_hr );

   
    if(my $v = $body_hr->{velocity} )
    {
        $body->velocity( @$v )
    }
    #HOLY COMMUNION 
    my $flesh = bless { body => $body }, $class;
    

    $flesh->setup( @_ );

    return $flesh;

}

sub import {
    my $class      = shift;
    my %properties = ( ref $_[0] ? %{ $_[0] } : @_ );
    my $caller     = caller;

    no strict 'refs';

    #  *{"${caller}::setup"}   = sub {$self};
}

sub body {
    return $_[0]->{body}
}

sub draw {

}



1;
