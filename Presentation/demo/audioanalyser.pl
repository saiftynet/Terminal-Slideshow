#!/usr/env perl
########## Audio Analyser ###########
use strict; use warnings;
use lib "../../../lib/";

use Term::Graille  qw/colour paint printAt cursorAt clearScreen border blockBlit block2braille pixelAt/;
use Term::Graille::Interact;
use Term::Graille::Menu; 
use Term::Graille::Font  qw/loadGrf fontWrite/;
use Term::Graille::Audio;
use Speech::SP0256;
use Speech::SP0256::Allophone;           # The allophone builder

my $beep=Term::Graille::Audio->new();    # TERM::Graille's Audio module
my $io=Term::Graille::Interact->new();   # For interactions menu and keyboard
my $chip=Speech::SP0256->new();
$io->{debugCursor}=[30,65];


my $grf=loadGrf("../../fonts/ZX Times.grf");

my $canvas = Term::Graille->new(
    width  => 120,
    height => 60,
    top=>12,
    left=>50,
    borderStyle => "double",
    borderColour => "blue",
    title => "Audio-Analyser",
    titleColour => "red",
  );
my $allophones=Speech::SP0256::Allophone::build();
my $pointer=0;
$chip->speak("hello");
$chip->speak("This is a sp ii tch synthes AY ser");

fontWrite($canvas,$grf,11,13,"Allophone");
fontWrite($canvas,$grf,13,10,"Waveform");
fontWrite($canvas,$grf,13,7,"Analyser");
$canvas->textAt(20,20,"An interactive console audio analyser for","green italic");
$canvas->textAt(40,16,"SP0256 Allophones","yellow italic");
$canvas->textAt(16,8,"Left - Right Arrow keys to cycle allophone","cyan bold");
$canvas->textAt(24,4,"Up Arrow key to play the sound","cyan bold");
   
my $menu=new Term::Graille::Menu(
          menu=>[["Allophone","Next","Prev","Quit"],
                 ["View","Stretch","Shrink"],
                 ["Play","Raw",["Filters","HiPass","LowPass"]],
                 "About"],
          pos=>[7,50],
          redraw=>\&refreshScreen,
          dispatcher=>\&menuActions,
          );

my %actions=(
     Next=>sub{$pointer=$pointer<$#{$allophones->{items}}?$pointer+1:0; plotAllophone()},
     Prev=>sub{$pointer=$pointer>0?$pointer-1:$#{$allophones->{items}}; plotAllophone()},
     Play=>sub{$beep->data2Device($allophones->{allophones}->{$allophones->{items}->[$pointer]}->{s});
		       $beep->data2Device($allophones->{allophones}->{PA4}->{s})},
);

sub plotAllophone{
	$canvas->{title}=" Analysing $allophones->{items}->[$pointer]";
	my $rawData=$allophones->{allophones}->{$allophones->{items}->[$pointer]}->{s};
	my @data=unpack "C*", $rawData;
	$canvas->clear();
	for my $pt (0..$#data){
		my $d=$data[$pt];
		my $c=(qw/white cyan blue green yellow yellow magenta red/)[abs ($d-128)/16];
		$canvas->set(120*$pt/@data,60*$d/255,colour($c));
	}
	$canvas->draw();
	$beep->data2Device($rawData);
	$beep->data2Device($allophones->{allophones}->{PA4}->{s});# beep a small silence to ensure bufer is emptied
	printAt(29,62,"\'".$allophones->{items}->[$pointer]."  Size ". scalar @data . "  Duration: ". @data/8 . "ms ", )
}

sub menuActions{
	my ($action,$gV)=@_;
	if (exists $actions{$action}){
		$actions{$action}->($gV)
	}
	else{

	}
};

$io->addObject(object => $menu,trigger=>"m");
$io->addAction("undef","[C",{proc=>sub{$actions{Next}->()},});
$io->addAction("undef","[D",{proc=>sub{$actions{Prev}->()},});
$io->addAction("undef","p",{proc=>sub{$actions{Play}->()},});
$io->addAction("undef","[A",{proc=>sub{$actions{Play}->()},});
$io->addAction("undef","q",{proc=>sub{exit;},});
$canvas->draw();
$io->run();

sub refreshScreen{
	clearScreen() unless (shift);
	$canvas->draw();
}
