#! /usr/bin/env perl
use strict; use warnings;
use utf8;
use lib "../../../lib";
use open ":std", ":encoding(UTF-8)";
use Term::Graille  qw/colour paint printAt cursorAt clearScreen border blockBlit block2braille pixelAt/;
use Term::Graille::Interact ;
use Term::Graille::Sprite;
use Term::Graille::Font  qw/loadGrf fontWrite/;
use Time::HiRes qw /sleep/;

my $VERSION=0.1;

# set up game artea
my $canvas = Term::Graille->new(
		width  => 150,
		height => 60,
		top=>4,
		left=>4,
		borderStyle => "double",
		title=>"Lunar Lander",
	  );
# Load fonts
my $grf=loadGrf("./fonts/Tentacle.grf");

# initialise sprite bank;
my $spriteBank=Term::Graille::SpriteBank->new();
foreach (1..8){
	$spriteBank->loadShape("./sprites/aa$_.spr");
}

splash();

my $lander=new Term::Graille::Sprite(data=>"aa3",pos=>[20,14],bounds=>[1,14,40,10], alwaysDraw=>1);
$spriteBank->addSprite("player",$lander);

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

#$spriteBank->drawAll($canvas);
	$canvas->draw();

my $pos=100;
my $dx=1;
my $dy=0;
my $stopUpdates=0;
my $altitude=10000;
my @arrows=qw/↑ ↗ → ↘ ↓ ↙ ← ↖/;
my $attitude=$arrows[0];


my $io=Term::Graille::Interact->new();
$io->{debugCursor}=[22,45];

$io->addAction(undef,"[C",{note=>"Rotate Left ",proc=>sub{
	(my $n=$lander->{data})=~s/aa//;
	$n++;$n=1 if $n>=9;
	$lander->{data}="aa".$n;
	$attitude=$arrows[$n-1]
	 }} );
$io->addAction(undef,"[D",{note=>"Rotate Right ",proc=>sub{
	(my $n=$lander->{data})=~s/aa//;
	$n--;$n=8 if $n<=0;
	$lander->{data}="aa".$n;
	$attitude=$arrows[$n-1]
	  }} );
$io->addAction(undef,"[A",{note=>"Thrust ",proc=>sub{
	if ($lander->{data} =~7)  {$dx-=0.5 unless $dx<=-3}
	elsif($lander->{data} =~3){$dx+=0.5 unless $dx>=3}
	elsif($lander->{data} =~1){$dy+=0.05}
	elsif($lander->{data} =~5){$dy-=0.05}
	elsif($lander->{data} =~2){$dx+=0.25;$dy+=0.05}
	elsif($lander->{data} =~4){$dx+=0.25;$dy-=0.05}
	elsif($lander->{data} =~6){$dx-=0.25;$dy-=0.005}
	elsif($lander->{data} =~8){$dx-=0.25;$dy+=0.005}
	
	  }} );
$io->addAction(undef,"[B",{note=>"Down ",proc=>sub{
	$dy=-0.01;
	  }} );
$io->addAction(undef,"p",{note=>"PaUSE ",     proc=>sub{
     $stopUpdates=$stopUpdates?0:1;}}    );

$io->updateAction(\&update);

$io->run();	


sub update{
	$pos+=$dx;
	$canvas->clear();
	#$lander->move([0,$dy]);
	$lander->{pos}->[0]=30-4*$dx;
	$altitude+=$dy*500;
	my $groundShift=$altitude/700>14?$altitude/700-14:0;
	$lander->{pos}->[1]=$altitude/700-$groundShift;
	my @list=(($pos+70)>$#ground)?(($pos..$#ground),(0..70-$#ground+$pos-1)):($pos..$pos+70);
	my $x=0;
	foreach (@list){
		my $ch=("▀","◢","◣")[$ground[$_]<=>$ground[$_-1]];
		my $pos=$ground[$_]*4+($ch eq "◣"?4:0);
		$canvas->textAt(2*$x++,$pos-$groundShift*4,$ch,$ch eq "▀"?"green":"yellow");
		
	}
	while ($pos>$#ground){
		$pos-=$#ground
	}
	$spriteBank->update($canvas);
	
	$canvas->draw();
	printAt(3,60,$lander->charsNear($canvas,"b") );
	die if join("",$lander->charsNear($canvas,"b"))=~/[▀◢◣]/;
	printAt(20,10," Horiz Vel=$dx Vert Velo=$dy Alt=".int($altitude)." Att=$attitude " );
}


sub splash{
  
  foreach (1..8){
	my $splashSpr=new Term::Graille::Sprite(data=>"aa$_",pos=>[-2+$_*8,14]);
	$spriteBank->addSprite("splash", $splashSpr);
  }
  $spriteBank->drawAll($canvas);
  fontWrite($canvas,$grf,2,8,"Lunar Lander v$VERSION");
  $canvas->draw();
  sleep 3;

	
}
