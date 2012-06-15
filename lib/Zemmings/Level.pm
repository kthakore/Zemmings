package Zemmings::Level;
use Avenger;
use SDLx::Sprite::Animated;

world->gravity( 0, -100 );

my $listener = Box2D::PerlContactListener->new();
$listener->SetPostSolveSub( sub { warn "collision" } );
world->{world}->SetContactListener( $listener );

update { world->update };

my $sky_rect = rect( 0, 0, app->w, app->h);

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
