#!/usr/bin/perl
#
# This script takes a Factual tab-delimited file as an argument
# and outputs the data belonging to VT and NH
#
# Usage:
#   
#    trim_dataset.pl us_places.factual.v3_38.1454477555.tab subtext_places.tab

# quit unless we have the correct number of command-line args
$num_args = $#ARGV + 1;
if ($num_args != 2) {
  print "\nUsage: trim_dataset.pl input_path output_path\n";
  exit;
}

open (INPUT, $ARGV[0]);
open (OUTPUT, ">>$ARGV[1]");

while(<INPUT>) {
  chomp;
  @entries = split("\t");
  if(@entries[6] =~ m/VT/ or @entries[6] =~ m/NH/) {
    print OUTPUT join("\t", @entries);
    print OUTPUT "\n";
  }
}
close(INPUT);
close(OUTPUT);
exit;
