package Zemmings;
use Avenger;
use Devel::Peek; 
use Zemmings::Map;

### THIS NEEDS TO GO TO AVENGER
   my $listener = Box2D::PerlContactListener->new();
    world->{world}->SetContactListener( $listener );
    $listener->SetPostSolveSub( sub { my $contact= shift; my $c_impulse = shift; 
                                        warn "Collision";
                                    }  );


sub new {
    my $package = shift;
    my %opts = @_;
 
    bless \%opts, $package;
}

sub create_map {
    my $self = shift;
    my %opts = @_;

    my @levels = glob "*.lvl";

    my $map = Zemmings::Map->new( file => $levels[ int rand @levels ] );
}

start 'MainScreen';

'brains';
