#! /usr/bin/env perl

use strict;
use warnings;

use Benchmark 'cmpthese';
use File::Slurp ();
use File::Slurp::Sane ();
use Encode 'resolve_alias';

my $filename = shift or die "No argument given";
my $count = shift || 1000;
my $factor = 10;

print "Slurping into a scalar\n";
cmpthese($count * $factor, {
	'Slurp'       => sub { my $content = File::Slurp::read_file($filename) },
	'Slurp-Sane'  => sub { my $content = File::Slurp::Sane::read_binary($filename) },
	'Traditional' => sub { open my $fh, '<', $filename or die $!; my $content = do { local $/; <$fh> } },
	'Unix'        => sub { open my $fh, '<:unix', $filename or die $!; my $content = do { local $/; <$fh> } },
});

print "\nSlurping into an array\n";
cmpthese($count, {
	'Slurp'       => sub { my @lines = File::Slurp::read_file($filename) },
	'Slurp+ref'   => sub { my $lines = File::Slurp::read_file($filename, array_ref => 1) },
	'Slurp-Sane'  => sub { my @lines = File::Slurp::Sane::read_lines($filename, 'latin1') },
	'Traditional' => sub { open my $fh, '<', $filename; my @lines = <$fh> },
});

print "\nSlurping into a loop\n";
cmpthese($count, {
	'Slurp'       => sub { for(File::Slurp::read_file($filename)) {} },
	'Slurp+ref'   => sub { for(@{ File::Slurp::read_file($filename, array_ref => 1) }) {} },
	'Slurp-Sane'  => sub { for(File::Slurp::Sane::read_lines($filename, 'latin1')) {} },
	'Traditional' => sub { open my $fh, '<', $filename; while(<$fh>) {} },
});

print "\nSlurping into an array, chomped\n";
cmpthese($count, {
	'Slurp'       => sub { my @lines = File::Slurp::read_file($filename, chomp => 1) },
	'Slurp+ref'   => sub { my $lines = File::Slurp::read_file($filename, array_ref => 1, chomp => 1) },
	'Slurp-Sane'  => sub { my @lines = File::Slurp::Sane::read_lines($filename, 'latin1', chomp => 1) },
	'Traditional' => sub { open my $fh, '<', $filename; my @lines = <$fh>; chomp @lines },
});


print "\nSlurping crlf into a scalar\n";
cmpthese($count * $factor, {
	'Slurp-Sane'  => sub { my $content = File::Slurp::Sane::read_text($filename, 'latin1', crlf => 1) },
	'Traditional' => sub { open my $fh, '<:crlf', $filename or die $!; my $content = do { local $/; <$fh> } },
});

print "\nSlurping crlf into an array\n";
cmpthese($count, {
	'Slurp-Sane'  => sub { my @lines = File::Slurp::Sane::read_lines($filename, 'latin1', crlf => 1) },
	'Traditional' => sub { open my $fh, '<:crlf', $filename; my @lines = <$fh> },
});

print "\nSlurping crlf into an array, chomped\n";
cmpthese($count, {
	'Slurp-Sane'  => sub { my @lines = File::Slurp::Sane::read_lines($filename, 'latin1', crlf => 1, chomp => 1) },
	'Traditional' => sub { open my $fh, '<:crlf', $filename; my @lines = <$fh>; chomp @lines },
});
print "\nNote that File::Slurp (as of 9999.19) does not validate its input, falsely improving its performance\n";

print "\nSlurping utf8 into a scalar\n";
cmpthese($count, {
	'Slurp'       => sub { my $content = File::Slurp::read_file($filename, binmode => ':raw:encoding(utf-8)') },
	'Slurp-Sane'  => sub { my $content = File::Slurp::Sane::read_text($filename) },
	'Traditional' => sub { open my $fh, '<:raw:encoding(utf-8)', $filename or die $!; my $content = do { local $/; <$fh> } },
	'Strict'      => sub { open my $fh, '<:raw:utf8_strict', $filename or die $!; my $content = do { local $/; <$fh> } },
});

print "\nSlurping utf8 into an array\n";
cmpthese($count, {
	'Slurp'       => sub { my @lines = File::Slurp::read_file($filename, binmode => ':raw:encoding(utf-8)') },
	'Slurp+ref'   => sub { my $lines = File::Slurp::read_file($filename, array_ref => 1, binmode => ':raw:encoding(utf-8)') },
	'Slurp-Sane'  => sub { my @lines = File::Slurp::Sane::read_lines($filename) },
	'Traditional' => sub { open my $fh, '<:raw:encoding(utf-8)', $filename; my @lines = <$fh> },
	'Strict'      => sub { open my $fh, '<:unix:utf8_strict', $filename; my @lines = <$fh> },
});

print "\nSlurping utf8 into an array, chomped\n";
cmpthese($count, {
	'Slurp'       => sub { my @lines = File::Slurp::read_file($filename, chomp => 1, binmode => ':raw:encoding(utf-8)') },
	'Slurp-Sane'  => sub { my @lines = File::Slurp::Sane::read_lines($filename, 'utf-8', chomp => 1) },
	'Traditional' => sub { open my $fh, '<:raw:encoding(utf-8)', $filename; my @lines = <$fh>; chomp @lines },
	'Strict'      => sub { open my $fh, '<:unix:utf8_strict', $filename; my @lines = <$fh>; chomp @lines },
});

