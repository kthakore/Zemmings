package Zemmings;
use Avenger;

use Zemmings::Map;

sub new {
    my $package = shift;
    my %opts = @_;
    bless \%opts, $package;
}

sub start {
    my $self = shift;
    my %opts = @_;
    my $level = delete $opts{level};
    my $map = Zemmings::Map->new( file => $level );
}

start 'MainScreen';

'brains';
