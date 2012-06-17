package Zemmings::Level;

use Avenger;
use SDLx::Sprite::Animated;
# use SVG::Parser;
# use SVG::Parser 'SVG::Parser::Expat'; # ... doesn't actually buy us anything
use Data::Dumper;
use XML::Parser;
use Box2D;

use Zemmings::SVG;

world->gravity( 0, -100 );

update { world->update };

my $sky_rect = rect( 0, 0, app->w, app->h);

my @structs;

my @polygon_objects = Zemmings::SVG->new( max_x => app->w, max_y => app->h, file => 'drawing.svg', world => world, )->get_objects or die;

my $floor = world->create_body( x => app->w / 2, y => 50, w => app->w, h => 100 );

my $protagonist = world->create_body(
        type => 'dynamic',
        x    => 50,
        y    => 150,
        w    => 32,
        h    => 32,
        friction => 0.0, # optional
        density  => 0.7, # optional
);

my $animation = SDLx::Sprite::Animated->new(image => 'share/stickzombie.png', width => 32, height => 32, );
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

    #

    app->draw_rect( $sky_rect, 0x00B9FFFF );
    app->draw_rect( $floor->rect, [0, 255, 0, 255] );

    #

    for my $ob ( @polygon_objects ) {

        my $shape = $ob->shape;
        my $color = $ob->color;
        my $body  = $ob->body;

        my @verts = map { $body->GetWorldPoint( $shape->GetVertex($_) ) } ( 0 .. $shape->GetVertexCount() - 1 );
        
        my @vx = map { $_->x } @verts;
        my @vy = map { $_->y } @verts;
        
        #  warn "vertxx xes: " . Data::Dumper::Dumper \@vx;
        # warn "vertex yes: " . Data::Dumper::Dumper \@vy;
        SDL::GFX::Primitives::filled_polygon_color( app, \@vx, \@vy, scalar @verts, $color || 0x000000ff ); # XXXXX

        # fun bit of debugging
        #    my $color = 0xffffffff;
        #    my $last_vert;
        #    for my $vert ( map { $body->GetWorldPoint( $shape->GetVertex($_) ) } ( 0 .. $shape->GetVertexCount() - 1 ) ) {
        #        SDL::GFX::Primitives::line_color( app, $last_vert->x, $last_vert->y, $vert->x, $vert->y, $color ) if $last_vert;
        #        $color -= 0x10101000;
        #        $last_vert = $vert;
        #    }

        # fun bit of debugging
        my $stupid_raw_shape_data     = $ob->{raw_shape_data} or die;
        my $color = 0xffffffff;
        my $last_vert;
        warn Data::Dumper::Dumper $stupid_raw_shape_data;
        for my $vert ( @$stupid_raw_shape_data ) {
            SDL::GFX::Primitives::line_color( app, $last_vert->[0], $last_vert->[1], $vert->[0], $vert->[1], $color ) if $last_vert;
            $color -= 0x10101000;
            $last_vert = $vert;
        }

    }

    # have the animation track the protagonist

    $animation->x($protagonist->x);
    $animation->y(app->h - $protagonist->y);
    $animation->draw(app);

    #

    app->update;
};

'all your zombies are belong to us';
