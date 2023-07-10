#! /usr/bin/env perl
use strict; use warnings;
use Term::Graille qw/colour paint printAt clearScreen border/;
use Image::Magick;

# convert2grl--converts an image to .grl format.

my %params=@ARGV;
my $canvas = Term::Graille->new(
    width  => $params{width}||120,
    height => $params{height}||70,
    top=>2,
    left=>2,
    borderStyle => "double",
  );
clearScreen();
my $inFile=$params{"-i"}||"images/WorldMap.png";
my $outFile=$params{-o}||($inFile=~s/\..+$//r).".grl";
loadImage($inFile);
$canvas->exportCanvas($outFile);

sub loadImage{
	my $imgfile=shift;
	my $image = Image::Magick->new();
	my $wh = $image->Read($imgfile); 
	$image->Resize(geometry => "$canvas->{width}x$canvas->{height}", filter=>"Cubic");
	warn $wh if $wh; 
	$image->set('monochrome'=>'True','dither'=>'True','dither-method'=>"Floyd-Steinberg");
	for (my $x =0;$x<$canvas->{width};$x++){
		for (my $y=0;$y<$canvas->{height};$y++){
			$canvas->set($x,$y) if $image->GetPixel("x"=>$x,"y",$canvas->{height}-$y); 
		}
	}
}
$canvas->draw();
printAt(21,4,"Viewing $inFile, saved as $outFile");
