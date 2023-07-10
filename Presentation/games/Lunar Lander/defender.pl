#! /usr/bin/env perl
use strict; use warnings;
use utf8;
use lib "../../../lib";
use open ":std", ":encoding(UTF-8)";
use Term::Graille  qw/colour paint printAt cursorAt clearScreen border blockBlit block2braille pixelAt/;
use Term::Graille::Interact ;
use Term::Graille::Sprite;
use Time::HiRes qw /sleep/;

my $canvas = Term::Graille->new(
		width  => 150,
		height => 60,
		top=>4,
		left=>4,
		borderStyle => "double",
		title=>"Bouncer",
	  );

my $spriteBank=Term::Graille::SpriteBank->new();
my $alt=0; my @ground;
for(0..1000){
	my @section;
	my $tAlt=$alt;
	my $slope=(1,0,-1)[rand()*3];
	my $distance=(rand()*4);
	foreach (0..$distance){
		$tAlt+=$slope;
		push @section,$tAlt;
	}
	next if (($tAlt<0)||($tAlt>8));
	push @ground, @section;
	$alt=$tAlt;
}

my $x=0;
foreach (0..2000){
	$canvas->clear();
	drawGround($_);
	$canvas->draw();
	sleep 0.5;
}

sub drawGround{
	my $pos=shift;
	while ($pos>@ground){
		$pos-=@ground;
	}
	my @list=(($pos+70)>$#ground)?(($pos..$#ground),(0..70-$#ground+$pos)):($pos..$pos+70);
	my $x=0;
	foreach (@list){
		my $ch=("█","◢","◣")[$ground[$_]<=>$ground[$_-1]];
		$canvas->textAt(2*$x++,$ground[$_]*4+($ch eq "◣"?4:0) ,$ch)
	}
	
}
