#! /usr/bin/env perl

use strict; use warnings;
use utf8;
use lib "../../../lib/";
use open ":std", ":encoding(UTF-8)";
use Term::Graille  qw/colour paint printAt cursorAt clearScreen border blockBlit block2braille pixelAt/;
use Term::Graille::Font  qw/convertDG saveGrf loadGrf fontWrite/;
use Term::Graille::Interact ;
use Term::Graille::Menu;
use Term::Graille::Selector;
use Term::Graille::Dialog ;
use Time::HiRes qw/sleep/;
use Data::Dumper;


# load or pass screen parameters
my %screenParams=@ARGV;
my %configFile=(do "./".$0."conf") if -e "./".$0."conf";
for (keys %configFile){
	$screenParams{$_}=$configFile{$_} unless exists $screenParams{$_};
};


my $width=164;
my $height=60;
my	$canvas = Term::Graille->new(
		width  => $width,
		height => $height,
		top=>10,
		left=>25,
		borderStyle => "double",
	  );


my $dir="../../fonts/";
my $fonts=new Term::Graille::FontSet(load=>"all",path=>$dir);;
my @fontNames=sort keys %{$fonts->{fontBank}};
my $fontPos=0;

my $dialog;  # container for dialogs#

my $io=Term::Graille::Interact->new();
$io->{debugCursor}=[2+$canvas->{top}+$canvas->{height}/4,$canvas->{left}+$canvas->{width}/2-20];

my $menu=new Term::Graille::Menu(  # no object offered so id will be o0 
          menu=>[["File","Load","Import","Quit"],
                 ["View","Next","Previous","Remove"],
                 "About"],
          redraw=>\&refreshScreen,
          dispatcher=>\&menuActions,
          pos=>[$canvas->{top}-2,$canvas->{left}],
          );

# in this case the dispatcher directs to subroutines based on name of  
my %actions = ( Load =>  sub{ load($dir)},
                Import =>  sub{ import($dir) },
                "Quit" =>sub {clearScreen() ;exit},
                Next=>  sub{ },
                Previous=>  sub{  },
                Remove=> sub{   },
              );

sub refreshScreen{
	clearScreen() unless (shift);
	$canvas->draw();
}
        
sub menuActions{ # dispatcher for menu
	my ($action,$bCrumbs)=@_;
	if (exists $actions{$action}){
		$actions{$action}->()
	}
	else{
		printAt(2,60,$action)
	}
};

my $y=$canvas->{height}/8-1+6;
foreach ("Font Coverter"," Viewer, exporter"){
	my $head=Term::Graille::FontQB::QBText($fonts,"ZX Times",$_);
	paint($head,"bold green");
	my $center=$canvas->{width}/4-(scalar @{$head->[0]})/2;
	$canvas->blockBlit($head,$center,$y);
	$y-=5;
	}
	
$canvas->draw();

$io->addAction(undef,"[C",{note=>"right arrow: cursor right ",proc=>sub{
	    $fontPos++ unless $fontPos>=$#fontNames;
	    showFont($fontNames[$fontPos]);
	    $canvas->draw();
	    } } );
$io->addAction(undef,"[D",{note=>"left arrow: cursor left   ",proc=>sub{
	    $fontPos-- unless $fontPos<=0;
	    showFont($fontNames[$fontPos]);
	    $canvas->draw();
	    } } );
$io->addAction(undef,"q",{note=>"q: quit   ",proc=>sub{
	    quit()
	    } } );	    
      
$io->addObject(object => $menu,trigger=>"m");
$io->run();

sub load{
	my ($dir,$filters)=@_;
	$dir//=".";
	$filters//="\.grf\$";
	opendir(my $DIR, $dir) || die "Can't open directory $dir: $!";
	my @files = sort(grep {(/$filters/i) && -f "$dir/$_" } readdir($DIR));
	closedir $DIR;
	my $selector=new Term::Graille::Selector(
          redraw=>\&refreshScreen,
          callback=>\&loadFile,
          options=>[@files],
          transient=>1,
          title=>"Load File",
          geometry=>[25,30],
          );
    $io->addObject(object => $selector, objectId=>"selector");
    $io->start("selector");
}	

sub loadFile{
	my $param=shift;
	$io->close();
	if ($param->{button} && $param->{button} eq "Cancel"){
		return;
		};
	my $fname=$param->{selected};
	clearScreen();
	$fname=~s/.grf$//i;	
	return errorMessage("Font $dir/$fname.grf not found")  unless (-e $dir.$fname.".grf");
	open my $grf,"<:utf8",$dir.$fname.".grf"  or do {
		errorMessage( "Unable to load fontfile $fname.grf");
		return;
		};
	my $data="";
	$data.=$_ while(<$grf>);
	close $grf;
	my $g=eval($data) or return errorMessage("unable to load font $fname.spr\n $!");
	$fonts->{$fname}=$g;
	showFont($fname);
}

sub showFont{
	my $fname=shift;
	#	printAt($canvas->{top}-2,$canvas->{left}+70,$fname."                 ");
	$canvas->{title}=$fname;
	$canvas->clear();
	my $head=Term::Graille::FontQB::QBText($fonts,$fname,$fname);
	paint($head,"green bold");
	my $center=$canvas->{width}/4-(scalar @{$head->[0]})/2;
	$canvas->blockBlit($head,$center,$canvas->{height}/4-1);
	
	fontWrite($canvas,$fonts->{fontBank}->{$fname},2,9, "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
	fontWrite($canvas,$fonts->{fontBank}->{$fname},2,5, "abcdefghijklmnopqrstuvwxyz");
	fontWrite($canvas,$fonts->{fontBank}->{$fname},2,2,  "1234567890+-*/<>{}[].,;#\$\%\&");
	
	$canvas->draw();
	
}

sub quit{
	$canvas->clear();
	$io->stop();
	fontWrite($canvas,$fonts->{fontBank}->{"Everest Bold"},10,10, "Quitting!");
	$canvas->draw();
	sleep 2;
	exit;
	
}

