modifyRRDs
==========

This is a utility script I put together as my first attempt at perl.  

The primary goal was to take an existing cacti RRD DS and splice it into its own RRD under a new name.
It can also provide a simplified rrdtool info, delete a given DS, or rename a given DS.

#Install#
##Perl
You will need a few perl CPAN modules to get started.

* warnings::everywhere
* RRD::Editor
* Date::Format
* File::Copy

Some of these are included by default in CPAN, but I don't recall which.  On redhat the process to install went [something like this](http://twiki.org/cgi-bin/view/TWiki/HowToInstallCpanModules):


    bash$> sudo perl -MCPAN -e shell
    cpan[1]> install warnings::everywhere
    cpan[2]> install Date::Format
    cpan[3]> install RRD:Editor
    cpan[4]> install File::Copy

##Cacti
Before trying to run the splice command, create your destination templates and spawn a new temporary instance of those graphs.  Those temporary graphs verify your new template and create the cacti backend metadata you're about to replace the underbelly of.  Be sure to disable the host for which you're modifying and allow any running pollers to complete so nothing should be writing to the RRD.

There isn't any specific preparation for deleting or renaming a DS other than the host being disabled.  However use these with caution as there won't be a backup or confirmation.

#Warnings#
This was my first attempt at perl, so parts of it arn't eligant.  I tried to catch a few error conditions that I wanted to protect myself against, but they are by no means complete.  This will _OVERWRITE_ the RRD you splice the DS into.  You should review this script before running it.  Verify that your RRA are setup identically between the splice source and destination or you may end up with data corruption.

#Usage#
List the DS & RRA for a given RRD:

```sudo perl modifyRRDs.pl lsds myfile.rrd```

Delete a DS from an RRD:

```sudo perl modifyRRDs.pl delds myfile.rrd targetDSName```

Rename a DS:

```sudo perl modifyRRDs.pl renameds myfile.rrd oldDSName newDSName```

Splice an old DS from one RRD to another RRD under a new name:

```sudo perl modifyRRDs.pl spliceds my.old.file.rrd my.new.file.rrd oldDSName newDSName```
