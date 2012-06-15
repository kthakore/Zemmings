package Zemmings::Level;
use Avenger;
use SDLx::Sprite::Animated;

update { world->update };

my $app_rect = rect( 0, 0, app->w, app->h);
# my $animation = SDLx::Sprite::Animated->new(image => 'share/stickzombie.png');
show {
    app->draw_rect( $app_rect, 0x3BB9FFFF );
    # app->draw_rect( $animation->rect, 0xFF000000 );

    app->update;
};

'all your zombies are belong to us';
