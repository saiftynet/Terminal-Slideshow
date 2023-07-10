#! /usr/bin/env perl
use strict; use warnings;
use lib "../../../lib/";
use Term::Graille qw/colour paint printAt clearScreen border/;;
use Term::Graille::Font  qw/convertDG saveGrf loadGrf fontWrite/;
use Image::Magick;
use Term::Graille::Interact ;
use Time::HiRes "sleep";

my $grf=loadGrf("../../fonts/ZX Times.grf");

my $animationFolder=$ARGV[0]||"../../animations/cheetah/";
opendir my $dir,$animationFolder or die;
my @files=sort grep !/^(\.|\.\.|.*\.pl)$/,readdir $dir;

my $canvas = Term::Graille->new(
    width  => 120,
    height => 50,
    top=>10,
    left=>50,
    borderStyle => "double",
    borderColour  => "yellow",
    title=>" Animation test ",
  );
my $animation=[];
my $animationframe=0;

$canvas->draw();

my $io=Term::Graille::Interact->new();
$io->{debugCursor}=[2+$canvas->{top}+$canvas->{height}/4,$canvas->{left}+$canvas->{width}/2-20];
$io->addAction(undef,"q",{note=>"q: quit   ",proc=>sub{
	    quit()
	    } } );	    

sub nextFrame{
	$animationframe++;
	$animationframe=0  if $animationframe>=@$animation;
	return unless ref $animation->[$animationframe];
	$canvas->{grid}=$animation->[$animationframe]; 
	$canvas->draw();
	}
      
$io->updateAction(\&nextFrame);
my $frame=0;
for my $image (@files){
	$canvas->clear();
	printAt(12+$frame,51,join("","Loading image ",$animationFolder.$image," ",++$frame,"\n"));
	$animation->[$frame]=[];
	loadImage($animationFolder.$image);
	#loadImage("./animations/chimp/chimp$frame.png"); 
	foreach my $row (0..$#{$canvas->{grid}}){
		foreach my $col(0..$#{$canvas->{grid}->[0]}){
			$animation->[$frame]->[$row]->[$col]=$canvas->{grid}->[$row]->[$col];
		}
	}
}

sleep 1;



$io->run();
sub loadImage{
	my $imgfile=shift;
	my $image = Image::Magick->new();
	my $wh = $image->Read($imgfile); 
	$image->Resize(geometry => "$canvas->{width}x$canvas->{height}");
	die $wh if $wh; 
	$image->set('monochrome'=>'True');
	$image->Negate();
	for (my $x =0;$x<$canvas->{width};$x++){
		for (my $y=0;$y<$canvas->{height};$y++){
			$canvas->set($x,$y) if $image->GetPixel("x"=>$x,"y",$canvas->{height}-$y); 
		}
	}
}

sub quit{
	$canvas->clear();
	$io->stop();
	fontWrite($canvas,$grf,4,10, "Quitting");
	$canvas->draw();
	sleep 2;
	exit;
	
}
