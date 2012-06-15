package Zemmings::Level;
use Avenger;
use SDLx::Sprite::Animated;

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
show {
    app->draw_rect( $sky_rect, 0x3BB9FFFF );
    app->draw_rect( $floor->rect, [0, 200, 0, 255] );

    # have the animation track the protagonist
    $animation->x($protagonist->x);
    $animation->y(app->h - $protagonist->y);
    $animation->draw(app);

    app->update;
};

'all your zombies are belong to us';
