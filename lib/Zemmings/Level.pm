package Zemmings::Level;
use Avenger;
use SDLx::Sprite::Animated;

update { world->update };

my $sky_rect = rect( 0, 0, app->w, app->h);

my $floor = world->create_body( x => app->w / 2, y => 50, w => app->w, h => 100 );

my $animation = SDLx::Sprite::Animated->new(image => 'share/stickzombie.png', width => 32, height => 32);
$animation->start;
show {
    app->draw_rect( $sky_rect, 0x3BB9FFFF );
    app->draw_rect( $floor->rect, [0, 200, 0, 255] );
    $animation->draw(app);

    app->update;
};

'all your zombies are belong to us';
