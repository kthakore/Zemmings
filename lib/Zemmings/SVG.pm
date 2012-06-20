package Zemmings::SVG;

use strict;
use warnings;

=head1 NAME

Zemmings::SVG

=head1 DESCRIPTION

Parse vector data out of SVG files and construct L<Box2D> polygons with them.  

=cut

use Data::Dumper;
use XML::Parser;
use Box2D;

=head2 new( file => $svg_file, world => $box2d_world_object, max_x => $screen_size_x, max_y => $screen_size_y, debug => 0, scale => 1/2, )

Construct a new L<Zemmings::SVG> objects from an SVG file.

XXX todo -- circles?  other shapes?

=head3 C<world>

An C<Avenger::World> object or C<Box2D::b2World> object.
Created C<Box2D::b2Body> objects get added to this to join the physical simulation.

=head3 C<max_x, max_y>

If provided, SVG polygon data will be scaled to fit within a box of this size.   
This may be useful for fitting a page of Inkscape data onto a screen.
If so, these may be taken from C<<app->w>> and C<<app->h>>.

On (detected) failure, it C<die>s, XXX currently without explanation; you have to look at the code and
see what it is trying to do at the point that it fails.

=head3 C<scale>

Scale factor (generally less than 1) between screen coordinates and world coordinates.  Box2D likes to deal in units
smaller than pixels; 300 is a big number for Box2D, for example, and numbers are floating point values, so units
small than 1 are fine.
Must match any other shapes you create yourself or pull in from other places.
This is applied on top of and after the C<max_x>, C<max_y> scale.
XXXXX how can I figure out what this is set to already?  $body->GetWorldPoint( $shape->GetVertex($_) ) doesn't give us back what we put in, it doesn't seem
XXXXX overly complicated and klunky
XXXX highly experimental

ALPHA 

=head1 TODO

* Doesn't yet figure out whether it needs to reverse order of the points so it doesn't wind the polygon in the wrong direction.

* Need local coordinate system for each polygon; right now they share one.  Need to clip, translate, and position each shape.

* Rather than passing a max_x and max_y, should preserve aspect ratio with a max_size option that scales input to fit input_max_x * input_max_y < max_size ** 2.  eg, an 800x600 scale input would be scaled down to 640x480 if max_size where specified as 307200.

=cut

sub new {

    my $package = shift;

    my %opts = @_;
    my $file = delete $opts{file};
    my $debug = delete $opts{debug};
    my $app_w = delete $opts{max_x};
    my $app_h = delete $opts{max_y};
    my $world = delete $opts{world};
    my $scale = delete $opts{scale} or die;
    die "unknown parameters: " . join ', ', keys %opts if keys %opts;

    $world = $world->{world} if ref($world) eq 'Avenger::World'; # no CreateBody() in Avenger::World XXXX should probably have one, then this wouldn't be needed

    my $self = bless { file => $file, debug => $debug, objects => [], }, $package;

    open my $fh, '<', $file or die $!;
    read $fh, my $buf, -s $fh;

    # my @d;
    my @paths;

    # eg:
    # <path
    #    style="fill:#000080;stroke:#000000;stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"
    #    d="M -58,1014.3622 C 240,842.36218 240,842.36218 240,842.36218 l 46,64 148,-86 178,98 164,-124 4,278.00002 -846,0 z"
    #    id="path2999"
    #    inkscape:connector-curvature="0" />

    my $p1 = new XML::Parser;

    $p1->setHandlers( Start => sub { 
        # warn Data::Dumper::Dumper $_[0] 
        # Start                (Expat, Element [, Attr, Val [,...]])
        my $expat = shift;
        my $element = shift;
        my %attrs = @_;
        # push @d, $attrs{d} if $element eq 'path' and exists $attrs{d}; 
        push @paths, \%attrs if $element eq 'path' and exists $attrs{d};  # we want the d and style keys in particular
    } );

    $p1->parse($buf);

    # warn Data::Dumper::Dumper \@paths if $debug;

    # build polygons from SVG data

    my @polygons;
    # my $last_point;

    for my $path ( @paths ) {

        my @polygon = $self->svg_path_data( $path->{d}, );
        # my ($min_x, $min_y, $max_x, $max_y) = $self->get_min_max_x_y( \@polygon );
        # $last_point = [$min_x, $min_y];
        # $last_point = [ -10, -10 ];

        # SVG path data closes the polygon but Box2D doesn't want it closed, so un-close it if it was properly closed
        if( $polygon[0]->[0] == $polygon[-1]->[0] and $polygon[0]->[1] == $polygon[-1]->[1] ) {
            pop @polygon;
        }

        push @polygons, \@polygon;

    }

    do {

        # scale to screen size

        my $world_min_x = 0;
        my $world_max_x = 0;
        my $world_min_y = 0;
        my $world_max_y = 0;
    
        for my $polygon ( @polygons ) {
    
            my ($min_x, $min_y, $max_x, $max_y) = $self->get_min_max_x_y( $polygon );
            $world_min_x = $min_x if $min_x < $world_min_x;
            $world_min_y = $min_y if $min_y < $world_min_y;
            $world_max_x = $max_x if $max_x > $world_max_x;
            $world_max_y = $max_y if $max_y > $world_max_y;
    
        }
    
        my $world_scale_x;
        my $world_scale_y;
    
        $world_scale_x = ( $app_w - 1 ) / $world_max_x;
        $world_scale_y = ( $app_h - 1 ) / $world_max_y;
    
        for my $polygon_i ( 0 .. @polygons-1 ) {
    
            my @polygon = @{ $polygons[$polygon_i] };
    
            # scale the polygon to the screen size (or the specified size)
    
            $_->[0] *= $world_scale_x * $scale for @polygon; # XXXXXXXXXXXXX
            $_->[1] *= $world_scale_y * $scale for @polygon;
    
        }
    };
    
    do {

        # translate polygon data to the upper left of the screen

        my $world_min_x = 0;
        my $world_max_x = 0;
        my $world_min_y = 0;
        my $world_max_y = 0;
    
        for my $polygon ( @polygons ) {
            my ($min_x, $min_y, $max_x, $max_y) = $self->get_min_max_x_y( $polygon );
            $world_min_x = $min_x if $min_x < $world_min_x;
            $world_min_y = $min_y if $min_y < $world_min_y;
            $world_max_x = $max_x if $max_x > $world_max_x;
            $world_max_y = $max_y if $max_y > $world_max_y;
        }
    
        for my $polygon_i ( 0 .. @polygons-1 ) {
    
            my @polygon = @{ $polygons[$polygon_i] };

            # translate the polygon into the screen area (or, in general, translate to appear in the specified area)
    
            if( $world_min_x < 0 ) {
                $_->[0] += abs($world_min_x) for @polygon;
            } else {
                # $_->[0] -= abs($world_min_x) for @polygon;
            }
    
            if( $world_min_y < 0 ) {
                $_->[1] += abs($world_min_y) for @polygon;
            } else {
                # $_->[1] -= abs($world_min_y) for @polygon;
            }
    
        }
    };

    # construct the Box2D::b2PolygonShape objects

    for my $polygon_i ( 0 .. @polygons-1 ) {

        my $path = $paths[ $polygon_i ];   # parallel arrays; this is a hashref of the attributes of the XML/SVG <path...> tag
        my @polygon = @{ $polygons[$polygon_i] }; # parallel arrays; this is the point data parsed out of the d attribute of the XML/SVG <path...> tag

        # find the local min and max and use that as the objects initial position

warn "before removing local mininums: " . Data::Dumper::Dumper \@polygon;
        my ( $local_min_x, $local_min_y, $local_max_x, $local_max_y ) = $self->get_min_max_x_y( \@polygon );
warn "local mininums: $local_min_x, $local_min_y";

        # translate the polygon into its own coordinate system that starts at 0,0 for that shape
        # this space that we substract out from the top left of the screen and the start of this polygon
        # gets used in a moment as the x, y position of this polygon on the screen.
        # this way, the shape is actually near its x, y position.

        for (@polygon) {
            $_->[0] -= $local_min_x; # XXXXXXXXXXX
            $_->[1] -= $local_min_y;
       }
warn "after removing local mininums: " . Data::Dumper::Dumper \@polygon;
        for (@polygon) { die if $_->[0] < 0;  die if $_->[1] < 0 }; 
        
        if( ! $self->convex_check( \@polygon ) ) {
            warn "well, our bloody polygon isn't convex; hell; trying to reverse the order of the points";
            @polygon = reverse @polygon;
            if( ! $self->convex_check( \@polygon ) ) {
                # XXXXXXX I don't think this will ever actually fix this; winding is a different test
                warn "well, hell; our bloody polygon *still* isn't convex; giving up on this one";
                next;
            } 
        }

        # splice @polygon, @polygon/2, 1, () while @polygon > 8; # XXXXXXXXX how to get more vertices?  is 8 a limitation?
        # @polygon = reverse @polygon; # XXXXXXXXXXXX okay, how do we figure out if we need to reverse this to reverse the winding?

        # Box2D::b2PolygonShape
     
        my $shape = Box2D::b2PolygonShape->new();
        $shape->Set(
            map Box2D::b2Vec2->new( @$_ ), @polygon
        );

        # Box2D::b2BodyDef

        my $bodyDef = Box2D::b2BodyDef->new();
        $bodyDef->type(Box2D::b2_staticBody);
        # $bodyDef->position->Set( $local_min_x, $app_h * $scale - $local_max_y  ); # XXXXX is Y stored inverse of screen?  if so, I need to reverse the Y coords before scaling etc; # XXXXX is Y stored inverse of screen?  if so, I need to reverse the Y coords before scaling et
        $bodyDef->position->Set( $local_min_x, $local_max_y  );
        my $body = $world->CreateBody($bodyDef);
# $body->GetTransform->SetIdentity;  # clobbers the polsition->Set stuff, so the position is apparently the vector in there
# die Data::Dumper::Dumper $body->GetTransform;

        # color

        my $color = $self->color_data( $path->{style} );

        # Zemmings::SVD::Object

        push @{ $self->{objects} }, bless {
            shape => $shape,
            body  => $body,
            color => $color,
            # ... extra stuff
            raw_shape_data => \@polygon,
            raw_starting_position => [ $local_min_x, $local_min_y ],
        }, 'Zemmings::SVG::Object';

    }

    return $self;

}

=head2 get_objects

Returns a list or arrayref of L<Zemmings::SVG::Object> objects
encapsulating a body, shape, and color for each path extracted from the SVG document.

=cut

sub get_objects {
    my $self = shift;
    return wantarray ? @{ $self->{objects} } : $self->{objects};
}

=cut

=head2 get_shapes

Returns a list/arrayref of the various polygons and as instances of L<Box2D::b2PolygonShape>.

=cut

sub get_shapes {
    my $self = shift;
    my @shapes = map $_->{shape}, @{ $self->{objects} };
    return wantarray ? @shapes : \@shapes;
}


=head2 svg_path_data( $path_tag_d_element_contents )

Return an array of points (each point being an arrayref containing an x and y element) given SVG path data.
This looks like this, for example:

       "M -58,1014.3622 C 240,842.36218 240,842.36218 240,842.36218 l 46,64 148,-86 178,98 164,-124 4,278.00002 -846,0 z"

That appears inside of an SVG C<< <path> >> tag's C<d> element. 

This is used internally as a helper method.

Specification for this obnoxious little compression format is at L<< http://www.w3.org/TR/SVG/paths.html#PathData >>.

=cut

sub svg_path_data {

    my $self = shift;
    my $d = shift;  # this is what SVG calls this attribute; it's unstructured data, and they can't even be bothered to call it "data".  it's just "d".  fuckers.
    # my $last_point = shift() || [ 0, 0 ];


warn "d: $d";

    my @polygon;
    my @draw = split m/ /, $d; 

    my $last_point = [ 0, 0 ];
    my $cmd;

    # d="M -58,1014.3622 C 240,842.36218 240,842.36218 240,842.36218 l 46,64 148,-86 178,98 164,-124 4,278.00002 -846,0 z"
    # style="fill:#000080;stroke:#000000;stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"

warn $d;
    my $debug = $self->{debug};

    while( my $token = shift @draw ) {
        if( $token =~ m/\d,-?\d/ ) {
            my $point = [ map 0+$_, split m/,/, $token ];
            # if( $cmd eq 'M' or $cmd eq 'L' or $cmd eq 'C' or ( $cmd eq 'm' and ! $last_point ) or ( $cmd eq 'l' and ! $last_point ) ) {
            if( $cmd eq 'M' or $cmd eq 'L' or $cmd eq 'C' ) {
                # move to absolute
                # we don't distinguish move-to and line-to because we're drawing a closed polygon; gaps aren't allowed
                warn "$cmd: move-to/line-to " . Data::Dumper::Dumper $point if $debug;
                unless( @polygon and $polygon[-1][0] == $point->[0] and $polygon[-1][1] == $point->[1] ) {
                    $last_point = $point;
                    push @polygon, $point;
                }
            } elsif( $cmd eq 'm' or $cmd eq 'l' or $cmd eq 'c' or $cmd eq 's' or $cmd eq 'q' or $cmd eq 't' or $cmd eq 'a') {
                # move to relative 
                die unless $last_point;
                $point->[0] += $last_point->[0];
                $point->[1] += $last_point->[1];
                warn "$cmd: move-to rel/line-to rel " . Data::Dumper::Dumper $point if $debug;
                unless( @polygon and $polygon[-1][0] == $point->[0] and $polygon[-1][1] == $point->[1] ) {
                    $last_point = $point;
                    push @polygon, $point;
                }
            } elsif( $cmd eq 'C' or $cmd eq 'c' ) {
                # curve to; ignore; the ones I see just contain the same point repeated several times
            } else {
                die "unknown SVG path command ``$cmd''; ignoring point data";
                # ignore
            }
        } else {
            $cmd = $token;
            if( uc($cmd) eq 'Z' ) {
                # make the last point in the polygon the same as the first point to close it
                # this one doesn't wait for coordinate data to come in
                # take care to copy the point so that references aren't shared; otherwise, if our user loops over each point modifying it, the first (and last) point will be modified twice!
                warn "$cmd: close polygon " . Data::Dumper::Dumper $polygon[0] if $debug;
                my $point_copy = [ @{ $polygon[0] } ];
                $last_point = $point_copy; # next <path> tag may continue relative to this one!
                push @polygon, $point_copy;
            }
        }
    }

    return wantarray ? @polygon : \@polygon;
}

=head2 color_data( $style_attribute_text )

Helper function.  Pulls color data out of the C<style> attribute of the C<path> tag.
XXX should maybe return C<undef> when no color data is extractable and let people set
their own defaults?  Or let people pass a default including C<undef>?
Problem with defaults is that you need a way to tell when they've been used.

=cut

sub color_data {
    my $self = shift;
    my $style = shift;
    my $default = shift;
    my $color;
    #    style="fill:#000080;stroke:#000000;stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"
    if( $style =~ m/fill:#([0-9a-zA-Z]{6})/ ) {
        $color = ( hex($1) << 8 ) | 0xff;  # no transparency
    } else {
        if( $default ) {
            $color = $default;
        } else {
            die "can't parse fill color data out of style ``$style'' and no default color was passed";
        }
    }
    return $color;
}

=head2 get_min_max_x_y( $point_data )

Finds the minimum and maximum X and Y coordinates and returns them.

=head3 $point_data

Point data for one polygon.  Arrayref of arrayrefs of X and Y points.

=head3 Return value

  ( $min_x, $min_y, $max_x, $max_y )

Internal helper method.

=cut

sub get_min_max_x_y {
    my $self = shift;
    my @polygon = @{ shift() };
    my @xs = map { $_->[0] } sort { $a->[0] <=> $b->[0] } @polygon;
    my @ys = map { $_->[1] } sort { $a->[1] <=> $b->[1] } @polygon;
    my $min_x = $xs[0];
    my $max_x = $xs[-1];
    my $min_y = $ys[0];
    my $max_y = $ys[-1];
    return ($min_x, $min_y, $max_x, $max_y);
}

=head2 convex_check( \@polygon_data )

Replicates the check inside of L<b2PolygonShape::Set> (C++ Box2D library) but without the fatal assert
attached to it.
Tells us if we should attempt to reverse the order of points.
Returns C<undef> on failure or C<1> to indicate the polygon looks okay.

=cut

sub convex_check {
    my $self = shift;
    my @polygon = @{ shift() } or die;

    # Ensure the polygon is convex and the interior
    # is to the left of each edge.

    for (my $i = 0; $i < @polygon; ++$i)
    {
        my $i1 = $i;
        my $i2 = $i + 1 < @polygon ? $i + 1 : 0;
        my $edge = [ $polygon[$i2]->[0] - $polygon[$i1]->[0], $polygon[$i2]->[1] - $polygon[$i1]->[1] ]; # b2Vec2 edge = m_vertices[i2] - m_vertices[i1];

        for (my $j = 0; $j < @polygon; ++$j)
        {
            # Don't check vertices on the current edge.
            if ($j == $i1 || $j == $i2)
            {
                next;
            }
            
            my $r = [ $polygon[$j]->[0] - $polygon[$i1]->[0], $polygon[$j]->[1] - $polygon[$i1]->[1] ]; # b2Vec2 r = m_vertices[j] - m_vertices[i1];

            # Your polygon is non-convex (it has an indentation) or
            # has colinear edges.
            # my $s = b2Cross($edge, $r);
            # Perform the cross product on two vectors. In 2D this produces a scalar.
            my $s = $edge->[0] * $r->[1] - $edge->[1] * $r->[0];

            warn "non-convexness detected looking at edges $j and $i1" if ! ( $s > 0.0 );
            return undef if ! ($s > 0.0);
        }
    }
    return 1;
}

#
#
#

=head2 Zemmings::SVG::Object->shape

The shape affects Box2D collision detection.
The vertices must be extracted and fed to SDL to draw the shape on the screen.

=head2 Zemmings::SVG::Object->body

The L<Box2D::b2BodyDef> object control physics parameters such as friction and weight.

=head2 Zemmings::SVG::Object->color

Fill color as extracted from the SVG C<path> element's C<style> tag.

=cut

package Zemmings::SVG::Object;

sub shape { $_[0]->{shape} }
sub body { $_[0]->{body} }
sub color { $_[0]->{color} }

*brains;
