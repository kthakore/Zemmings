package Zemmings::Map;

sub map :lvalue { $_[0]->{map} }
sub max_x { $_[0]->{max_x} }
sub max_y { $_[0]->{max_y} }

sub get { $_[0]->{map}->[$_[1]]->[$_[2]] }
sub set { $_[0]->{map}->[$_[1]]->[$_[2]] = $_[3] }

sub new {
    my $package = shift;
    my %opts = @_;
    my $data = delete $opts{file};

    my $map;  # ->[$x]->[$y]
    my $map_max_x = 0;
    my $map_max_y = 0; 
	   
    die unless @levels;
    open my $fh, '<', $fn or die "$fn: $!";
    my $y = 0;
    while( my $line = readline $fh ) {
        chomp $line;
        my @line = split m//, $line;
        for my $x ( 0 .. $#line ) {
            $map->[$x]->[$y] = $line[$x];
            $map_max_x = $x if $x > $map_max_x;
        }
        $y++;
    }
    $map_max_y = $y;
    $self->max_x = $map_max_x;
    $self->max_y = $map_max_y;
    1;
}

1;
