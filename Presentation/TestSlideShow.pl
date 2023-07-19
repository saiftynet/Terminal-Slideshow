#! /usr/bin/env perl
use strict; use warnings;
use lib "../../lib/";
use Term::Graille qw/colour paint printAt clearScreen border/;
use Term::Graille::Animate qw/blockMove/;
use Term::Graille::Font qw/loadGrf/;
use Term::Graille::Interact ;
use Term::Graille::Menu;
use Time::HiRes "sleep";


# load or pass screen parameters
my %screenParams=@ARGV;
my %configFile=(do "./".$0."conf") if -e "./".$0."conf";
for (keys %configFile){
	$screenParams{$_}=$configFile{$_} unless exists $screenParams{$_};
};


my $theme={
	titleFont=>"ZX Venice",
	titleStyle=>"yellow bold",
	listFont=>"Everest",
	listStyle=>"cyan bold",
	headFont=>"Calstone",
	headStyle=>"green bold",	
	
};

my $slides=[]; makeSlides();
my $presentationName="Term::Graille Slide Show Application";
my $slideNo=-100;
my $currentSlide=0;
my $fonts=new Term::Graille::FontSet(load=>"all",path=>"../fonts/");
my $width=$screenParams{width}//248;
my $height=$screenParams{height}//96;

my $canvas = Term::Graille->new(
		width  => $width,
		height => $height,
		top=>$screenParams{top}//4,
		left=>$screenParams{left}//4,
		borderStyle => "double",
		title => "Term::Graille Slide Show Application",
	  );
	  
my $leftMargin=15;
my $cursorPos=[$leftMargin,$canvas->{height}/4-3];

my $io=Term::Graille::Interact->new();
$io->{debugCursor}=[$canvas->{height}/4+6,$canvas->{width}/2-25];


my $menu=new Term::Graille::Menu(  # no object offered so id will be o0 
          menu=>[["Presentation","Load","Refresh","First Slide","Next Slide","Previous Slide","Export","Quit"],
                 ["View","Refresh","Theme",[qw/Resize Width+ Width- Height+ Height-/],],
                 ["Run","ASCIIloscope.pl","editor.pl","invaders.pl","breakout.pl"],
                 "About"],
          redraw=>\&refreshScreen,
          dispatcher=>\&menuActions,
          );	  
          
my %actions = (  Load => sub{ load()},
				"First Slide"=>sub {$slideNo=0;showSlide()},
				"Next Slide" =>sub {$slideNo=-1 if ($slideNo==-100); $slideNo++ unless $slideNo>=$#$slides; showSlide()},
				"Previous Slide" =>sub {$slideNo-- unless $slideNo <= 0;showSlide()},
				"Refresh"=>sub {refresh()},
				"Width+" =>sub {$canvas->{width}+=16;resize();},
				"Width-" =>sub {$canvas->{width}-=16;resize();},
				"Height+" =>sub {$canvas->{height}+=16;resize();},
				"Height-" =>sub {$canvas->{height}-=16;resize();},
				"Quit"=>sub { exit; },
                "Logo"=>sub{logo()},
                "About"=>sub{
					clearScreen();
					border(4,6,18,70,"double","red");
					drawHead("Terminal\nSlide Show\nApplication");
					},
				  "Quit"=>sub{exit;}
              );
              
$actions{"About"}->();
              
sub menuActions{ # dispatcher for menu
	my ($action,$gV)=@_;
	if (exists $actions{$action}){
		$actions{$action}->($gV)
	}
	else{
		printAt($canvas->{top}-2,$canvas->{left}+56,$action)
	}
};	  

sub load{
};

sub showSlide{
	$canvas->clear();
	$canvas->{title}=$presentationName.": Slide $slideNo";
	$slides->[$slideNo]->();
}

sub refresh{
	clearScreen();
	$canvas->clear();
	$slides->[$currentSlide]->();
}

sub resize{
	$io->{debugCursor}=[$canvas->{height}/4+6,$canvas->{width}/2-25];
	refresh();
}
	  
$io->addObject(object => $menu,trigger=>"m");

$io->addAction(undef,"[C",{note=>"right arrow: cursor right ",proc=>sub{
	$actions{"Next Slide"}->();
	} } );
$io->addAction(undef,"[D",{note=>"left arrow: cursor left   ",proc=>sub{
	$actions{"Previous Slide"}->();
	} } );
$io->addAction(undef,"r",{note=>"r: Refresh screen  ",proc=>sub{
	$actions{"Refresh"}->();
	} } );
      
$io->run();

sub refreshScreen{
	clearScreen() unless (shift);
	$canvas->draw();
}

sub centerX{
	my $block=shift;
	return $canvas->{width}/4-(scalar @{$block->[0]})/2;
}

sub centerY{
	my $block=shift;
	return $canvas->{height}/8-(scalar @$block/2);
}

sub center{
	my $block=shift;
	return [centerX($block),centerY($block)];
}

sub nextLine{
	$cursorPos=[$leftMargin,$cursorPos->[1]+3]
}

my $slideParams={
	leftMargin=>2,
	topMargin=>$canvas->{height}/4-3,
	rightMargin=>$canvas->{width}/2-2,
	bottomMargin=>2,	
};


sub render{
	my (%params)=@_;
	
	for ($params{item}){
		/image/i && do{
			my $image=$params{image};
			my $block=$canvas->importBlock($image);
			my $style=$params{style}//"bold";
			paint($block,$style);
			my $entry=$params{entry}//"appear";
			my $position=$params{position}?[split(",",$params{position})]:center($block);
			my $colour=$params{colour}//"bold";
			entry($block,$position,$entry);
		};
		/head/i && do{
			my $text=$params{text};	
			my $font=$params{font} // $theme->{headFont};
			my $style=$params{style} // $theme->{headStyle};
			my @lines=split("\n",$text);
			my $y=$canvas->{height}/8-1+(3* scalar @lines);
			foreach (@lines){
				my $head=Term::Graille::FontQB::QBText($fonts,$font,$_);
				paint($head,$style);
				my $center=$canvas->{width}/4-(scalar @{$head->[0]})/2;
				$canvas->blockBlit($head,$center,$y);
				$y-=5;
			};
		};
		/title/i && do{
			my $text=$params{text};	
			my $font=$params{font} // $theme->{titleFont};
			my $style=$params{style} // $theme->{titleStyle};
			my $head=Term::Graille::FontQB::QBText($fonts,$font,$text);
			paint($head,$style);
			$canvas->blockBlit($head,centerX($head),$canvas->{height}/4-1);
		};
		/list/i && do{
			my $list=$params{list};	
			my $font=$params{font} // $theme->{listFont};
			my $style=$params{style} // $theme->{listStyle};
			my $entry=$params{entry}//"appear";
			my $position=$params{position}?[split(",",$params{position})]:nextLine();
			my $row=0;
			foreach (@$list){
				my $block=$fonts->makeTextBlock($font,$_);
				paint($block,$style);
				my $yPos=$canvas->{height}/4-8-3*$row++ ;
				entry($block,[$position->[0],$yPos],$entry);#blockMove($canvas,$block,[80,$yPos],[32,$yPos],1);
			} 
		};
		/externalapp/i && do{
			$canvas->clear();
			$canvas->draw();
			my $path=$params{path}//".";
			my $app=$params{app};
			error("App '$app' not found in path '$path'") unless (($app=~/\.pl$/)&& (-e $path."/".$app));
			system("cd $path;perl ./$app")
		};			
	}
}


sub makeSlides{ 
	$presentationName="PerlaySation";
	$slides=[
		sub{drawImageContent("perlaystation.grl",[$canvas->{width}/4-50,$canvas->{height}/8+4]);
			drawHead("The PerlayStation\nGames Console");
		},
		sub{  drawImageContent("saif1.grl",[2,18]);
			  drawTitle("WHOIS::SAIFTYNET");
			  drawlistContent(["Name: Saif Ahmed","Day Job:Surgeon","Location: UK","Perl CV: Grants Sec","CPAN ID: SAIFTYNET","GUIDeFATE, Graille"],
					[32,$canvas->{height}/4-3],
					"appear",
					);
		},
		sub{
			  drawTitle("Contents");
			  drawlistContent(["Background","Initial Motivation","Distraction","Current Status","Future","Conclusion"],
					[15,$canvas->{height}/4-3],
					"appear",
					);
		}, 
		sub{
			drawHead("Robotics, Sense and Control\nVisualisation of signals");
		},
		sub{
			  drawTitle("ASCIIloscope");
			  drawlistContent(["Realtime Data Acquisition","Interactivity","Variable sample rate","Auto scaling","Data Analysis","From a Terminal"],
					[15,$canvas->{height}/4-3],
					"appear",
					);
		},
		sub {
			  runExternal("Asciiloscope","asciiloscope.pl","ASCIIloscope")
		},
		sub{
			  drawTitle("Extending goals");
			  drawlistContent(["Higher Resolution","Other Display Forms","Simulation","Terminal Graphical Toolkit"],
					[15,$canvas->{height}/4-3],
					"appear",
					);
		},
		sub{
			  drawTitle("Extending Terminal Graphics");
			  drawlistContent(["Sub-Character Plotting","Drawille (asciimoo) ","Term::Drawille (hoelzro)","<green bold>Term::Graille"],
					[15,$canvas->{height}/4-3],
					"key",
					);
		},
		sub{
			  drawTitle("Braille and Quarter Block");
			  drawlistContent(["Braille:", "* 2x4 dots","* Logical", "* Gaps"],
					[10,$canvas->{height}/4-3],
					"appear",
					);
			  sleep .5;
			  drawlistContent(["Quarter Block:", "* 2x2 blocks","* Arbitrary", "* No Gaps"],
					[60,$canvas->{height}/4-3],
					"appear",
					);
		},
		sub{
			  drawTitle("Term::Graille");
			  drawlistContent(["Heterogenic Drawing","Canvas ","Multiple primitives","Scriptable","Extendible"],
					[15,$canvas->{height}/4-3],
					"slide from right",
					);
		},		
		sub {
			 runExternal("demo","demo.pl", "Term::Graille");
		},
		sub{
			drawHead("Deviation From Goal");
		},
		
		sub{
			  drawTitle("Destructive Distractions");
			  #drawImageContent("diversion.grl",[2,25]);
			  drawlistContent(["Graphical ToolKit","Test applications needed","* Control","* Visualisation","* Responsiveness","Best way?...make Games"],
					[15,$canvas->{height}/4-3],
					"apppear",
					);
		},
		sub{
			  drawTitle("Games as a Motivator");
			  drawImageContent("zxspectrum.grl",[2,18]);
			  drawlistContent(["* Simple Games","* Many Genres","* Apply stress","* Try Features","* Fun Frills"],
					[60,$canvas->{height}/4-3],
					"appear",
					);
		},
		sub{
			drawHead("Extensions");
		},
		sub{
			  drawTitle("Interactivity");
			  drawlistContent(["* Detect Keypresses","* Menu","* Selectors","* Dialog Boxes","* Screeen updates"],
					[15,$canvas->{height}/4-3],
					"apppear",
					);
		},
		sub {
			  drawTitle("Fonts");
			  runExternal("demo","fontviewer.pl");
			  
		},
		sub{
			  drawTitle("Image conversions");
			  drawImageContent("larry-ascii.grl",[50,18],"key");
			  drawImageContent("larry-ascii.grl",[50,18],"clear");
			  
			  drawImageContent("larry-wall.grl",[50,18],"key");
			  drawImageContent("larry-wall.grl",[50,18],"clear");
			  
			  drawImageContent("damian.grl",[50,18],"key");
			  drawImageContent("damian.grl",[50,18],"clear");
			  
			  drawImageContent("elizabeth.grl",[50,18],"key");
			  drawImageContent("elizabeth.grl",[50,18],"clear");
			  
			  drawImageContent("brian.grl",[50,18],"key");
			  drawImageContent("brian.grl",[50,18],"clear");
			  
			  drawImageContent("olaf.grl",[50,18],"key");
			  drawImageContent("olaf.grl",[50,18],"clear");
			  
			  drawImageContent("makoto.grl",[50,18]);
			  
		},		
		sub{
			  drawTitle("Animation");
			 runExternal("demo","testanimate.pl");
		},
		sub{
			  drawTitle("Sprites");
			 runExternal("demo","sprites.pl","Sprites");
		},
		sub{
			  drawTitle("Audio and Speech");
			  runExternal("demo","piano graille.pl","Audio and Speech");
		},
		sub{
			  runExternal("demo","audioanalyser.pl","Audio and Speech");
		},
		sub{
			drawHead("Example Games");
		},
		sub{
			  drawTitle("Space Invaders");
			  runExternal("games/Invaders","invaders.pl");
		},
		sub{
			  drawTitle("Breakout");
			  runExternal("games/Breakout","breakout.pl");
			  
		},
		sub{
			drawHead("Useful(ish) Side Apps");
		},
		sub{
			  drawTitle("Text editor");
			  runExternal("demo","editor.pl");
		},
		sub{
			  drawTitle("Sprite editor");
			  runExternal("demo","spritemaker.pl");
		},
		sub{
			  drawTitle("Conclusion & Thanks");
			  drawlistContent(["Criticisms","Suggestions","Collaboration","<yellow bold>saiftynet\@gmail.com"],
					[5,$canvas->{height}/4-3],
					"apppear",
					);
		},
		]
}

sub drawTitle{
	my $text=shift;
	#my $title=$fonts->makeTextBlock($theme->{titleFont},$text);
	
	my $title=Term::Graille::FontQB::QBText($fonts,$theme->{titleFont},$text);
	paint($title,$theme->{titleStyle});
	my $center=$canvas->{width}/4-(scalar @{$title->[0]})/2;
	$canvas->blockBlit($title,$center,$canvas->{height}/4-1);
	$canvas->draw();
}

sub drawHead{
	my $text=shift;	
	my @lines=split("\n",$text);
	my $y=$canvas->{height}/8-1+(3* scalar @lines);
	foreach (@lines){
		my $head=Term::Graille::FontQB::QBText($fonts,$theme->{headFont},$_);
		paint($head,$theme->{headStyle});
		my $center=$canvas->{width}/4-(scalar @{$head->[0]})/2;
		$canvas->blockBlit($head,$center,$y);
		$y-=5;
	}
	$canvas->draw();
}

sub drawImageContent{
	my ($image,$position,$entry)=@_;
	my $block=$canvas->importBlock("images/$image");
	entry($block,$position,$entry);
	$canvas->draw();	 
}

sub drawlistContent{
	my ($list,$position,$entry)=@_;
	my $row=0;
	my $style=$theme->{listStyle};my $item;
	foreach (@$list){
		if ($_=~/^(<([a-z ]+)>)?(.*)$/){
			$item=$3;
			$style= $2 if $2;
			};
		my $block=$fonts->makeTextBlock($theme->{listFont},$item);
		paint($block,$style);
		my $yPos=$canvas->{height}/4-6-3*$row++ ;
		entry($block,[$position->[0],$yPos],$entry);#blockMove($canvas,$block,[80,$yPos],[32,$yPos],1);
	}
	$canvas->draw();
}

sub drawBlock{
	my ($block,$position,$entry)=@_;
	entry($block,@$position);
}

sub runExternal{
	my ($path,$application,$title,)=@_;	
	drawHead("Running External\nApplication");
	sleep 0.5;
	$canvas->clear(); 
	drawTitle($title) if $title;
	$canvas->draw(); 
	$io->stop();
	system("cd $path;perl \"./$application\"");
	drawHead("closed External\nApplication");
	$io->run();	
}

sub entry{
	my ($block,$position,$entry)=@_;
	$entry//="empty";
	for ($entry){
		/slide from right/ && do {
			   blockMove($canvas,$block,[80,$position->[1]],$position,.2);
			   sleep .5;
			   last;
		     };
		/clear/ && do {
			$block=$canvas->blankBlock($block);
			$canvas->blockBlit($block,@$position); 
			last;
		     };
		/key/ && do {
			$canvas->blockBlit($block,@$position); 
			$canvas->draw();
			<STDIN>; 
			last
		     };
		$canvas->blockBlit($block,@$position);     
	}
			$canvas->draw();
	
}

