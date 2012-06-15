package Zemmings::Level;
use Avenger;

update { world->update };

my $app_rect = rect( 0, 0, app->w, app->h);
show {
    app->draw_rect( $app_rect, 0x3BB9FFFF );

    app->update;
};

'all your zombies are belong to us';
