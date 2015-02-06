package File::Slurper;
use strict;
use warnings;

use Carp 'croak';
use Exporter 5.57 'import';
use File::Spec::Functions 'catfile';
our @EXPORT_OK = qw/read_binary read_text read_lines write_binary write_text read_dir/;

sub read_binary {
	my $filename = shift;

	# This logic is a bit ugly, but gives a significant speed boost
	# because slurpy readline is not optimized for non-buffered usage
	open my $fh, '<:unix', $filename or croak "Couldn't open $filename: $!";
	if (my $size = -s $fh) {
		my $buf;
		my ($pos, $read) = 0;
		do {
			defined($read = read $fh, ${$buf}, $size - $pos, $pos) or croak "Couldn't read $filename: $!";
			$pos += $read;
		} while ($read && $pos < $size);
		return ${$buf};
	}
	else {
		return do { local $/; <$fh> };
	}
}

my $crlf_default = $^O eq 'MSWin32' ? 1 : 0;
my $has_utf8_strict = eval { require PerlIO::utf8_strict };

sub _text_layers {
	my ($encoding, $options) = @_;
	my $crlf = !! delete $options->{crlf};
	$crlf = $crlf_default if $crlf eq 'auto';

	if ($encoding =~ /^(latin|iso-8859-)1$/i) {
		return $crlf ? ':unix:crlf' : ':raw';
	}
	elsif ($has_utf8_strict && $encoding =~ /^utf-?8\b/i) {
		return $crlf ? ':unix:utf8_strict:crlf' : ':unix:utf8_strict';
	}
	else {
		# non-ascii compatible encodings such as UTF-16 need encoding before crlf
		return $crlf ? ":raw:encoding($encoding):crlf" : ":raw:encoding($encoding)";
	}
}

sub read_text {
	my ($filename, $encoding, %options) = @_;
	$encoding ||= 'utf-8';
	my $layer = _text_layers($encoding, \%options);
	return read_binary($filename) if $layer eq ':raw';

	open my $fh, "<$layer", $filename or croak "Couldn't open $filename: $!";
	return do { local $/; <$fh> };
}

sub write_text {
	my ($filename, undef, $encoding, %options) = @_;
	$encoding ||= 'utf-8';
	my $layer = _text_layers($encoding, \%options);

	open my $fh, ">$layer", $filename or croak "Couldn't open $filename: $!";
	print $fh $_[1] or croak "Couldn't write to $filename: $!";
	close $fh or croak "Couldn't write to $filename: $!";
	return;
}

sub write_binary {
	return write_text(@_[0,1], 'latin-1');
}

sub read_lines {
	my ($filename, $encoding, %options) = @_;
	$encoding ||= 'utf-8';
	my $layer = _text_layers($encoding, \%options);

	open my $fh, "<$layer", $filename or croak "Couldn't open $filename: $!";
	return <$fh> if not %options;
	my @buf = <$fh>;
	close $fh;
	chomp @buf if $options{chomp};
	return @buf;
}

sub read_dir {
	my ($dirname, %options) = @_;
	opendir my ($dir), $dirname or croak "Could not open $dirname: $!";
	my @ret = grep { not m/ \A \.\.? \z /x } readdir $dir;
	@ret = map { catfile($dirname, $_) } @ret if $options{prefix};
	closedir $dir;
	return @ret;
}

1;

# ABSTRACT: A simple, sane and efficient module to slurp a file

=head1 SYNOPSIS

 use File::Slurper 'read_text';
 my $content = read_text($filename);

=head1 DESCRIPTION

B<DISCLAIMER>: this module is experimental, and may still change in non-compatible ways.

This module provides functions for fast and correct slurping and spewing. All functions are optionally exported.

=func read_text($filename, $encoding, %options)

Reads file C<$filename> into a scalar and decodes it from C<$encoding> (which defaults to UTF-8). Can optionally take this named argument:

=over 4

=item * crlf

This forces crlf translation on the input. The default for this argument is off. The special value C<auto> will set it to a platform specific default value.

=back

=func read_binary($filename)

Reads file C<$filename> into a scalar without any decoding or transformation.

=func read_lines($filename, $encoding, %options)

Reads file C<$filename> into a list/array after decoding from C<$encoding>. By default it returns this list. Can optionally take this named argument:

=over 4

=item * chomp

C<chomp> the lines.

=back

=func write_text($filename, $content, $encoding, %options)

Writes C<$content> to file C<$filename>, encoding it to C<$encoding> (which defaults to UTF-8). It can optionally take a C<crlf> named argument that works exactly as in read_text.

=func write_binary($filename, $content)

Writes C<$content> to file C<$filename> as binary data.

=func read_dir($dirname, %options)

Open C<dirname> and return all entries except C<.> and C<..>. Can optionally take this named argument:

=over 4

=item * prefix

This will prepend C<$dir> to the entries

=back

=head1 TODO

=over 4

=item * C<open_text>?

=back

=head1 SEE ALSO

=over 4

=item * L<Path::Tiny|Path::Tiny>

A minimalistic abstraction not only around IO but also paths.

=item * L<IO::All|IO::All>

An attempt to expose as many IO related features as possible via a single API.

=back

=cut
