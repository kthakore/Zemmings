package Zemmings;
use Avenger;
use Zemmings::Map;
use Data::Dumper;

### THIS NEEDS TO GO TO AVENGER

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
