#!/usr/bin/perl -w
#######################################
# modifyRRDs.pl
# v0.0.1
# 6/2/14
#
# I made this because I was dumb and put too many things in an RRD when setting up cacti.
# I needed to keep my historical data, but splice the old DS into a new RRD under a new DS name.
# This script is pretty rough as it was my first attempt at perl and should not be run without reviewing first.
#
# It is assumed that before you run this you've created the appropriate templates in cacti and created
# an instance of the graph you are about to splice into.  This is to get the cacti backend correctly positioned
# to accept the historical data.
#
# Note that this will destroy any data included in the splice target RRD.
#
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#########################################

#Disable warnings inside RRD:Editor module from CPAN
no warnings::anywhere qw(uninitialized);
use RRD::Editor ();
use Date::Format;
use File::Copy;
use warnings qw(uninitialized);

# verify input parameters
my $in_oper  	        = $ARGV[0] if defined $ARGV[0];
my $in_rrd             = $ARGV[1] if defined $ARGV[1];
my $in_var1             = $ARGV[2] if defined $ARGV[2];
my $in_var2             = $ARGV[3] if defined $ARGV[3];
my $in_var3             = $ARGV[4] if defined $ARGV[4];

# usage notes
if (
        ( ! defined $in_oper ) ||
        ( ! defined $in_rrd )
        ) {
        print   "usage:\n";
        print   "\tlsds &lt;rrd&gt;\n";
	print	"\tdelds &lt;rrd&gt; &lt;target ds&gt;\n";
	print	"\trenameds &lt;rrd&gt; &lt;current name&gt; &lt;new name&gt;\n";
        print	"\tspliceds &lt;old rrd&gt; &lt;new rrd&gt; lt&;old ds name&gt; &lt;new ds name&gt;\n";
	exit 1;
}

my $rrd = RRD::Editor->new();

if (
	($in_oper eq "lsds")
	) {
	$rrd->open($in_rrd);
	my $info = $rrd->info();
	my %indexHash;
	my %dsIndexHash;
	while ($info =~ m/ds\[(.*)\].index = (\d+)/g){
		#print "$1\t$2\n";
		$dsIndexHash{$2}=$1;
		printf("DSName: %-18s DSIndex: %-4s\n",$1,$2);
	}
	print "\n";
	for(my $index = 0; $index < $rrd->num_RRAs(); $index++) {
		my %rra;
		$rra{'RowCount'} = $rrd->RRA_numrows($index);
		my ($t,$val) = $rrd->RRA_el($index, $dsIndexHash{$index}, $rrd->RRA_numrows($index)-1);
		$rra{'CF'} = $rrd->RRA_type($index);
		$rra{'LastUpdateStr'} = time2str("%D %r %Z",$t);
		$rra{'LastUpdateUnix'} = $t;
		$rra{'LastValue'} = $val;
		printf("RRA Index: %-4s CF: %-8s RowCount: %-6s LastUpdated: %-18s\n",$index,,$rra{'CF'},$rra{'RowCount'},$rra{'LastUpdateStr'});
	}
	$rrd->close();
}

if (
	($in_oper eq "delds")
	) {	
	if(!defined $in_var1)
	{
		print "RRD DS Index missing!\n";
		exit 1;
	}

	$rrd->open($in_rrd);
	my %dsNameHash;
	my $info = $rrd->info();
	while ($info =~ m/ds\[(.*)\].index = (\d+)/g){
		$dsNameHash{$1}=$2;
	}
	if (!exists($dsNameHash{$in_var1}))
	{
		print "DS Name was not found in target RRD!\n";
		exit 1;
	}
	
	$rrd->delete_DS($in_var1);
	#workaround for bug https://rt.cpan.org/Public/Bug/Display.html?id=89662
	my $rrdTemp = $in_rrd."temp";
	$rrd->save($rrdTemp);
	$rrd->close();
	move $rrdTemp,$in_rrd;
}

if (
	($in_oper eq "renameds")
	) {
	if(!defined $in_var1 || !defined $in_var2)
	{
		print "Missing current or new name!\nusage: renameds currentds newds\n";
		exit 1;
	}
	$rrd->open($in_rrd);
	my %dsNameHash;
	my $info = $rrd->info();
	while ($info =~ m/ds\[(.*)\].index = (\d+)/g){
		$dsNameHash{$1}=$2;
	}
	if (!exists($dsNameHash{$in_var1}))
	{
		print "Current DS Name was not found in target RRD!\n";
		exit 1;
	}
	if (exists($dsNameHash{$in_var2}))
	{
		print "Target DS Name was found in target RRD!\n";
		exit 1;
	}
	$rrd->rename_DS($in_var1,$in_var2);
	$rrd->save();
	$rrd->close();
}

if (
	($in_oper eq "spliceds")
	) {
	if(!defined $in_var1 || !defined $in_var2 || !defined $in_var3)
	{
		print "Required Parameters Missing\n";
		exit 1;
	}
	$rrd->open($in_rrd);
        my %dsNameHash1;
        my $rraCount1 = $rrd->num_RRAs();
	my $info1 = $rrd->info();
        while ($info1 =~ m/ds\[(.*)\].index = (\d+)/g){
                $dsNameHash1{$1}=$2;
        }
        if (!exists($dsNameHash1{$in_var2}))
        {
                print "Old DS Name was not found in old RRD!\n";
                exit 1;
        }
	$rrd->close;
	$rrd->open($in_var1);
	my %dsNameHash2;
	my $rraCount2 = $rrd->num_RRAs();
	my $info2 = $rrd->info();
        while ($info2 =~ m/ds\[(.*)\].index = (\d+)/g){
                $dsNameHash2{$1}=$2;
        }
        if (!exists($dsNameHash2{$in_var3}))
        {
                print "New DS Name was not found in new RRD!\n";
                exit 1;
        }	
	if (keys(%dsNameHash2) != 1)
	{
		print "More than one DS in target RRD!\n";
		exit 1;
	}
	if ($rraCount1 != $rraCount2)
	{
		print "WARNING: Number of RRA do not match! ($rraCount1 != $rraCount2)\n";
	}
	$rrd->close;
	copy $in_var1,$in_var1.".bak";
	copy $in_rrd,$in_var1;
	delete $dsNameHash1{$in_var2};
	my $args;
	while ( my ($key, $value) = each(%dsNameHash1) ) {
        	print "Stripping out $key\n";
		#$args = ($0,"delds",$in_var1,$key);
		$args = "perl $0 delds $in_var1 $key";
		system($args) == 0 or die "system $args failed: $?\n";
	}
	if($in_var2 ne $in_var3)
	{
		print "Renaming $in_var2 to $in_var3\n";
		#$args = ($0,"renameds",$in_var1,$in_var2,$in_var3);
		$args = "perl $0 renameds $in_var1 $in_var2 $in_var3";
		system($args) == 0 or die "system $args failed: $?\n";
	}
}
exit 0;
