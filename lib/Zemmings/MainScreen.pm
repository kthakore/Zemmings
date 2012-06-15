package Zemmings::MainScreen;
use Avenger;
use Avenger::Widget::Menu;

sub startup {
    my $self = shift;

    menu(
        sub {
            'New Game' => sub { load('Level', 1) },
            'Quit'     => sub { exit },
        }, {
            font => 'share/DroidSansMonoDotted.ttf'
        },
    );
}

show { app->update };

'all your zombies are belong to us';
