#! /usr/bin/env perl
use strict; use warnings;
use utf8;
use lib "../../../lib";
use open ":std", ":encoding(UTF-8)";
use Term::Graille  qw/colour paint printAt cursorAt clearScreen border blockBlit block2braille pixelAt/;
use Term::Graille::Interact ;
use Term::Graille::Sprite;
use Term::Graille::Audio;
use Term::Graille::Font  qw/loadGrf fontWrite/;
use Time::HiRes qw/sleep/;


# load or pass screen parameters
my %screenParams=@ARGV;
my %configFile=(do "./".$0."conf") if -e "./".$0."conf";
for (keys %configFile){
	$screenParams{$_}=$configFile{$_} unless exists $screenParams{$_};
};

my $canvas = Term::Graille->new(
    width  => 120,
    height => 25,
    top=>12,
    left=>40,
    borderStyle => "double",
    borderColour  => "yellow",
    title=>" Sprite test ",
  );
my $animation=[];
my $animationframe=0;


my @colours=qw/red blue green yellow cyan magenta white/;
my $setPix=[['⡀','⠄','⠂','⠁'],['⢀','⠠','⠐','⠈']];
my $unsetPix=[['⢿','⣻','⣽','⣾'],['⡿','⣟','⣯','⣷']];


$canvas->draw();

my $spriteBank=Term::Graille::SpriteBank->new();

foreach my $colour(qw/red yellow green magenta cyan white blue/){
	$spriteBank->addShape($colour."man",[[colour($colour)."⠀","⢤","⠿","⡿","⡤","⠀","⠀","⠀".colour("reset")],["⠀","⣈","⣲","⣖","⠋","⠀","⠀","⠀"],["⠪","⠀","⣇","⣸","⠑","⠄","⠀","⠀"],["⠠","⣞","⠁","⠈","⠳","⠔","⠂","⠀"]]);
}

my $man1=new Term::Graille::Sprite(
    data=>[["⠀","⢤","⠿","⡿","⡤","⠀","⠀","⠀"],["⠀","⣈","⣲","⣖","⠋","⠀","⠀","⠀"],["⠪","⠀","⣇","⣸","⠑","⠄","⠀","⠀"],["⠠","⣞","⠁","⠈","⠳","⠔","⠂","⠀"]],
    pos=>[5,5],
    vel=>[2,0],
    
);

$man1->blit($canvas);
my $walkingMan=[
[["⠀","⢤","⠿","⡿","⡤","⠀","⠀","⠀"],["⠀","⣈","⣲","⣖","⠋","⠀","⠀","⠀"],["⠪","⠀","⣇","⣸","⠑","⠄","⠀","⠀"],["⠠","⣞","⠁","⠈","⠳","⠔","⠂","⠀"]],
[["⠀","⢤","⠿","⡿","⡤","⠀","⠀","⠀"],["⠀","⣈","⣲","⣖","⠋","⠀","⠀","⠀"],["⠸","⠀","⣇","⣸","⠑","⠒","⠂","⠀"],["⠰","⠖","⠃","⠘","⣇","⡀","⠀","⠀"]],
[["⠀","⢤","⠿","⡿","⡤","⠀","⠀","⠀"],["⠀","⠈","⣲","⣖","⠋","⠀","⠀","⠀"],["⠀","⠪","⣇","⡸","⠑","⠄","⠀","⠀"],["⠀","⠲","⢺","⣟","⠂","⠀","⠀","⠀"]],
[["⠀","⢤","⠿","⡿","⡤","⠀","⠀","⠀"],["⠀","⠈","⣲","⣖","⠋","⠀","⠀","⠀"],["⠀","⠪","⣇","⡸","⠑","⠄","⠀","⠀"],["⠀","⠲","⢺","⣟","⠂","⠀","⠀","⠀"]],
];
foreach (0..$#$walkingMan){
	my $temp=$walkingMan->[$_];
	$temp=rotate($temp,"Horiz");
	$walkingMan=[@$walkingMan,$temp]
};


my $blank=$canvas->blankBlock($walkingMan->[0]);
my $direction=1;
my $x=2;
for (0..200){
	$canvas->draw();
	sleep 0.1;
	$man1->blankPrev($canvas);
	$man1->move();
	$man1->blit($canvas);
	$man1->setShape($walkingMan->[$_ %4+($man1->{vel}->[0]<0?4:0)]);
	$man1->{vel}=[-2.5,0] if ($man1->{pos}->[0]>=50);
	$man1->{vel}=[2.5,0] if ($man1->{pos}->[0]<=2);
	
}


sub rotate{
	my ($spr,$rot)=@_;
	my $newSprite=[map {[("⠀")x8]}(0..3)];
	if ($rot eq "RL Diag"){
		for my $c (0..15){
			for my $d(0..15){
				set($newSprite,$c,$d,getValue($spr,15-$d,15-$c))
			}
		}
	}
	elsif ($rot eq "LR Diag"){
		for my $c (0..15){
			for my $d(0..15){
				set($newSprite,$c,$d,getValue($spr,$d,$c))
			}
		}
	}
	elsif ($rot eq "Horiz"){
		for my $c (0..15){
			for my $d(0..15){
				set($newSprite,$c,$d,getValue($spr,15-$c,$d))
			}
		}
	}
	elsif ($rot eq "Vert"){
		for my $c (0..15){
			for my $d(0..15){
				set($newSprite,$c,$d,getValue($spr,$c,15-$d))
			}
		}
	}
	elsif ($rot eq "270"){
		for my $c (0..15){
			for my $d(0..15){
				set($newSprite,$c,$d,getValue($spr,$d,15-$c))
			}
		}
	}
	elsif ($rot eq "90"){
		for my $c (0..15){
			for my $d(0..15){
				set($newSprite,$c,$d,getValue($spr,15-$d,$c))
			}
		}
	}
	elsif ($rot eq "180"){
		for my $c (0..15){
			for my $d(0..15){
				set($newSprite,$c,$d,getValue($spr,15-$c,15-$d))
			}
		}
	}
	else{
		return
	}
	return $newSprite;
}
 
sub getValue{
	my ($spr,$x,$y)=@_;
	my ($chX,$chY,$r,$c)=locate($x,$y);
	my $contents=$spr->[$#{$spr}-$chY]->[$chX];
	my $bChr=chop($contents);
	my $orOp=(ord($unsetPix->[$c]->[$r]) | ord($bChr));
	#printAt(22,20,"$x,$y ".$unsetPix->[$c]->[$r]." ".$sprite->[$#{$sprite}-$chY]->[$chX]);
	return chr($orOp) eq '⣿'?1:0;
}

sub set{
	my ($spr,$x,$y,$value)=@_;
	my ($chX,$chY,$r,$c)=locate($x,$y);
	my $chHeight=scalar @{$spr};
	my $contents=$spr->[$#{$spr}-$chY]->[$chX];	
	my $bChr=chop($contents);
	if ($value=~/^[a-z]/){$contents=colour($value);}
	elsif ($value=~/^\033\[/){$contents=$value;}
	else {$contents=""};
	# ensure character is a braille character to start with
	$bChr='⠀' if (ord($bChr)&0x2800 !=0x2800); 
	
	$spr->[$#{$spr}-$chY]->[$chX]=$contents.$value?         # if $value is false, unset, or else set pixel
	   (chr( ord($setPix-> [$c]->[$r]) | ord($bChr) ) ):
	   (chr( ord($unsetPix-> [$c]->[$r]) & ord($bChr)));
}

sub locate{
	my ($x,$y)=@_;
	my $chX=int($x/2);my $c=$x-2*$chX;
	my $chY=int($y/4);my $r=$y-4*$chY;
	return ($chX,$chY,$r,$c);
}
 

