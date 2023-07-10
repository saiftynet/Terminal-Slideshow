# Perl Polling Test

# Title: Perl to chipKIT Serial Poll Test
# Author: James M. Lynes, Jr.
# Version: 1.0
# Creation Date: June 10, 2012
# Modification Date: June 10, 2012

use strict;
use warnings;

use Time::HiRes ("sleep");      # allow fractional sleeps 

# Initialize the serial port - creates the serial port object $Arduino

use Device::SerialPort::Arduino;

  my $Arduino = Device::SerialPort::Arduino->new(
    port     => '/dev/ttyUSB0',
    baudrate => 9600,
    databits => 8,
    parity   => 'none',
  );

my $file="";
my $count=1000;
while($count>0) {
 # $Arduino->communicate('P');                     # Send a poll
  my $str=$Arduino->receive();
  $file.=$str."\n";
  print ($Arduino->receive(), "\n");              # Print poll response
  #sleep (0.001) ;   
  $count--;                                 # Delay until next poll
}


open(my $fh, '>', "test.data") or die $!;
print $fh $file;
close($fh);
