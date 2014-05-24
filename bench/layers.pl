#! /usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Benchmark 'cmpthese';

sub read_text {
	my ($filename, $layers) = @_;
	open my $fh, "<$layers", $filename;
	my $foo = do { local $/; <$fh> };
	return;
}

sub read_lines {
	my ($filename, $layers) = @_;
	open my $fh, "<$layers", $filename;
	my @foo = <$fh>;
	return;
}

my $count = shift // 100;
my $filename = shift // 'test.txt';
my $encoding = shift // 'utf-8';

say "Read utf8 encoded text file, decode with :encoding\n";
cmpthese($count, {
	'crlf:encoding'     => sub { read_text($filename, ":crlf:encoding($encoding)") },
	'unix:crlf:encoding' => sub { read_text($filename, ":unix:crlf:encoding($encoding)") },
	'unix:crlf:encoding:perlio' => sub { read_text($filename, ":unix:crlf:encoding($encoding):perlio") },
	'encoding:crlf'     => sub { read_text($filename, ":encoding($encoding):crlf") },
	'encoding:crlf:perlio'     => sub { read_text($filename, ":encoding($encoding):crlf:perlio") },
});

say "\nRead utf8 encoded text file, decode with :utf8_strict\n";
cmpthese($count * 10, {
	':utf8_strict'      => sub { read_text($filename, ":utf8_strict") },
	':unix:utf8_strict' => sub { read_text($filename, ":unix:utf8_strict") },
	':unix:utf8_strict:perlio' => sub { read_text($filename, ":unix:utf8_strict:perlio") },
});

say "\nRead utf8 encoded text file with optional crlf line endings, decode with :utf8_strict\n";
cmpthese($count * 10, {
	':crlf:utf8_strict'        => sub { read_text($filename, ":crlf:utf8_strict") },
	':utf8_strict:crlf'        => sub { read_text($filename, ":utf8_strict:crlf") },
	':utf8_strict:crlf:perlio' => sub { read_text($filename, ":utf8_strict:crlf:perlio") },
	':utf8_strict:perlio'      => sub { read_text($filename, ":utf8_strict:perlio") },
	':utf8_strict'             => sub { read_text($filename, ":utf8_strict") },
});

say "\nRead lines of utf8 encoded text file with optional crlf line endings, decode with :utf8_strict\n";
cmpthese($count * 10, {
	':crlf:utf8_strict'        => sub { read_lines($filename, ":crlf:utf8_strict") },
	':utf8_strict:crlf'        => sub { read_lines($filename, ":utf8_strict:crlf") },
	':utf8_strict:crlf:perlio' => sub { read_lines($filename, ":utf8_strict:crlf:perlio") },
	':utf8_strict:perlio'      => sub { read_lines($filename, ":utf8_strict:perlio") },
	':utf8_strict'             => sub { read_lines($filename, ":utf8_strict") },
});

say "\nRead text file optionally doing crlf translation\n";
cmpthese($count * 10, {
	':unix:crlf'        => sub { read_text($filename, ":unix:crlf") },
	':unix:crlf:perlio' => sub { read_text($filename, ":unix:crlf:perlio") },
	':unix'             => sub { read_text($filename, ":unix") },
	':raw'              => sub { read_text($filename, ":raw") },
});

say "\nRead text file into lines, optionally doing crlf translation\n";
cmpthese($count * 10, {
	':unix:crlf'        => sub { read_lines($filename, ":unix:crlf") },
	':unix:crlf:perlio' => sub { read_lines($filename, ":unix:crlf:perlio") },
	':raw'              => sub { read_lines($filename, ":raw") },
});
