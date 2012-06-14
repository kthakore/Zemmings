package Avenger::Actor;
use Avenger;

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
