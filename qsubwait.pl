#!/usr/bin/perl
# Submits a job to the cluster and waits until the job is finished.
# Copyright © 2009, 2012 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ":utf8";
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use cluster;

# Create a temporary script file.
# Derive its name from the first argument to qsub.
my $scriptname = $ARGV[0];
$scriptname =~ s-^.*/([^/]+)$-$1-;
my $scriptpath = "/tmp/$scriptname.$$.csh";
open(SCRIPT, ">$scriptpath") or die("Cannot write $scriptpath: $!\n");
print SCRIPT ("#!/bin/tcsh -f\n");
print SCRIPT (join(' ', @ARGV), "\n");
close(SCRIPT);
# Submit to the cluster the job described by the script.
my $jobid = cluster::qsub('script' => $scriptpath, 'memory' => '31g');
# Periodically ask the cluster what is the current status of the job.
print STDERR ("Waiting for job no. $jobid to finish...\n");
cluster::waitfor(30, $jobid);
# Remove the temporary script.
unlink($scriptpath) or die("Cannot remove $scriptpath: $!\n");
