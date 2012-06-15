package Zemmings::Level;
use Avenger;
use SDLx::Sprite::Animated;

update { world->update };

my $app_rect = rect( 0, 0, app->w, app->h);
my $animation = SDLx::Sprite::Animated->new(image => 'share/stickzombie.png', width => 32, height => 32);
$animation->start;
show {
    app->draw_rect( $app_rect, 0x3BB9FFFF );
    $animation->draw(app);

    app->update;
};

'all your zombies are belong to us';
