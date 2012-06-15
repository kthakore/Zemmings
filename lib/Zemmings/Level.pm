package Zemmings::Level;
use Avenger;

#Is the zemming level screen

#Single Zemming Actor
#NOTE: Always has to have actor in BASE::Actor namespace

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

    # SINGLETONS FOR THE LEVEL     
    level  => 1,
    points => 500,

    # ...

};

update {

};

show {

};

 

1;
