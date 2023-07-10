use strict; use warnings;
use lib "../../../lib";
use Term::Graille::Audio;
use Term::Graille::Interact;

my $beep=Term::Graille::Audio->new();    # TERM::Graille's Audio module
my $io=Term::Graille::Interact->new();   # capture keyboard actions

my ($keyboard,$key2note)=$beep->makeKeyboard(30,10,1);
print $keyboard;
print "\033[25;30H","Start pressing keys... Escape to exit;\n";

$io->{debugCursor}=[28,30];

$io->addAction("MAIN","others",{proc=>sub{
      my ($pressed,$GV)=@_;
      $beep->playSound(undef, $key2note->{$pressed}) if exists $key2note->{$pressed};
    }
  }
);

$io->addAction("MAIN","esc",{proc=>sub{
      exit 1;
    }
  }
);

$io->run();
