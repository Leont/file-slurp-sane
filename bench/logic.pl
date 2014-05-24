#! /usr/bin/env perl

use strict;
use warnings;
use Carp 'croak';

use Benchmark 'cmpthese';

my $filename = shift or die "No argument given";
my $count = shift || 10000;

sub read_binary1 {
	my $filename = shift;
	my $buf;

	open my $fh, '<:unix', $filename or croak "Couldn't open $filename: $!";
	my $size = -s $fh;
	my ($pos, $read) = 0;
	do {
		defined($read = read $fh, $buf, $size - $pos, $pos) or croak "Couldn't read $filename: $!";
		$pos += $read;
	} while ($read && $pos < $size);
	return $buf;
}

sub read_binary2 {
	my $filename = shift;

	open my $fh, '<:unix', $filename or croak "Couldn't open $filename: $!";
	return do { local $/; <$fh> };
}

cmpthese($count, {
	complicated => sub { read_binary1($filename) },
	simple      => sub { read_binary2($filename) },
});
