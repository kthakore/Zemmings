package Zemmings::Level;

use Avenger;
use SDLx::Sprite::Animated;
# use SVG::Parser; # dies on not being able to figure out the line ending
use Data::Dumper;
use XML::Parser;
use Box2D;

world->gravity( 0, -100 );

update { world->update };

my $sky_rect = rect( 0, 0, app->w, app->h);

0 and do { # XXX sdw, this blows up for me with "perl: Collision/Shapes/b2PolygonShape.cpp:149: void b2PolygonShape::Set(const b2Vec2*, int32): Assertion `edge.LengthSquared() > 1.19209289550781250000e-7F * 1.19209289550781250000e-7F' failed."  commiting it for now, will try to look at it in the morning.  this is supposed to find the polygons in SVGs and turn them into Box2D polygons.
    open my $fh, '<', 'drawing.svg' or die $!;
    read $fh, my $buf, -s $fh;

    my @d;

    my $p1 = new XML::Parser;
    $p1->setHandlers( Start => sub { 
       # warn Data::Dumper::Dumper $_[0] 
       # Start                (Expat, Element [, Attr, Val [,...]])
       my $expat = shift;
       my $element = shift;
       my %attrs = @_;
       push @d, $attrs{d} if $element eq 'path' and exists $attrs{d}; 
    } );
    $p1->parse($buf);
    warn Data::Dumper::Dumper \@d;

    for my $polygon ( @d ) {
        # my @polygon = map { [ map $_?$_/10:0, map int, split m/,/, $_ ] } grep m/\d/, split m/ /, $polygon; 
        my @polygon = map { [ map int, split m/,/, $_ ] } grep m/\d/, split m/ /, $polygon; 
        splice @polygon, @polygon/2, 1, () while @polygon > 8;

        warn Data::Dumper::Dumper \@polygon;
     
        my $bodyDef = Box2D::b2BodyDef->new();
        $bodyDef->type(Box2D::b2_staticBody);
        # $bodyDef->position->Set( 0, app->h - 30 );
        $bodyDef->position->Set( app->w * 100, 50 );
        my $body = world->{world}->CreateBody($bodyDef);
     
        my $shape = Box2D::b2PolygonShape->new();
        $shape->Set(   # *instead* of SetAsBox
            map Box2D::b2Vec2->new( @$_ ), @polygon
        );
    }

};




my $floor = world->create_body( x => app->w / 2, y => 50, w => app->w, h => 100 );

my $protagonist = world->create_body(
        type => 'dynamic',
        x    => 50,
        y    => 150,
        w    => 32,
        h    => 32,
        friction => 0.0, # optional
        density  => 0.7, # optional
        collided => sub { warn 'Collided' } 
);

my $animation = SDLx::Sprite::Animated->new(image => 'share/stickzombie.png', width => 32, height => 32);
$animation->start;

event 'key_down' => sub {
    my ($x, $y);
    given (my $key = shift) {
        when ('up')    { $y = 200  };
        when ('left')  { $x = -200 };
        when ('right') { $x = 200  };
    };
    $protagonist->velocity( $x, $y );
};

show {
    app->draw_rect( $sky_rect, 0x3BB9FFFF );
    app->draw_rect( $floor->rect, [0, 255, 0, 255] );

    # have the animation track the protagonist
    $animation->x($protagonist->x);
    $animation->y(app->h - $protagonist->y);
    $animation->draw(app);

    app->update;
};

'all your zombies are belong to us';
