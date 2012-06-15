package Zemmings::Level;
use Avenger;

#Is the zemming level screen

#Single Zemming Actor
actor 'Zemming' => {
    body => {
        x        => 10,
        y        => 600,
        velocity => { x => 5, y => 0 }
    }
};

#Loading JSON Actors
#actors => 'level1.json'
#Looks for actors arrayref[hash] in data/level1.json

setup {
    
    level  => 1,
    points => 500,

    # ...

};

update {

};

show {

};

 

1;
