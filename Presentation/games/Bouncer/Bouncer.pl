#! /usr/bin/env perl
use strict; use warnings;
use utf8;
use lib "../../../lib";
use open ":std", ":encoding(UTF-8)";
use Term::Graille  qw/colour paint printAt cursorAt clearScreen border blockBlit block2braille pixelAt/;
use Term::Graille::Interact ;
use Term::Graille::Sprite;

my $spriteBank=Term::Graille::SpriteBank->new();

foreach (1..5){
	$spriteBank->addSprite("ball",new Term::Graille::Sprite(
	    data=>[[colour((qw/red yellow green magenta cyan white blue/)[rand()*6])."◢"," ","◣".colour("reset")],
	           [colour((qw/red yellow green magenta cyan white blue/)[rand()*6])."◥"," ","◤".colour("reset")],],
	    pos=>[rand()*60+2,rand()*13+2],
	    vel=>[1,1],
	    bounds=>[1,14,70,0],skip=>5));
}

my $canvas = Term::Graille->new(
		width  => 150,
		height => 60,
		top=>4,
		left=>4,
		borderStyle => "double",
		title=>"Bouncer",
	  );

$spriteBank->drawAll($canvas);
$canvas->draw();


my $io=Term::Graille::Interact->new();
$io->updateAction(\&update);
$io->run();	

sub update{
	foreach my $bll (@{$spriteBank->{groups}->{ball}}){
		my ($edge,$dir)=$bll->edge();
		if ($edge ne ""){
			$bll->{vel}->[1]=abs($bll->{vel}->[1])*$dir->[1] if ($dir->[1]);
			$bll->{vel}->[0]=abs($bll->{vel}->[0])*$dir->[0] if ($dir->[0]);
		}
	}
	$spriteBank->update($canvas);
	$canvas->draw();
}
