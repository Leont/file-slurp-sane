package File::Slurp::Sane;
use strict;
use warnings;

use Carp 'croak';
use Encode 'resolve_alias';
use Exporter 5.57 'import';
use File::Spec::Functions 'catfile';
use FileHandle;
our @EXPORT_OK = qw/read_binary read_text read_lines read_dir/;

sub read_binary {
	my ($filename, %options) = @_;
	my $buf_ref = defined $options{buf_ref} ? $options{buf_ref} : \my $buf;

	open my $fh, '<:unix', $filename or croak "Couldn't open $filename: $!";
	if (my $size = -s $fh) {
		my ($pos, $read) = 0;
		do {
			defined($read = read $fh, ${$buf_ref}, $size - $pos, $pos) or croak "Couldn't read $filename: $!";
			$pos += $read;
		} while ($read && $pos < $size);
	}
	else {
		${$buf_ref} = do { local $/; <$fh> };
	}
	close $fh;
	return if not defined wantarray or $options{buf_ref};
	return $buf;
}

my $crlf_default = $^O eq 'MSWin32' ? 1 : 0;

sub _text_layers {
	my ($encoding, $options) = @_;
	my $canonical = resolve_alias($encoding) or croak "Unknown encoding '$encoding'";
	my $crlf = exists $options->{crlf} ? !! delete $options->{crlf} : $crlf_default;
	return $crlf ? ':crlf' : ':raw' if $canonical eq 'iso-8859-1';
	if ($crlf) {
		my $crlf_safe = $canonical =~ /^(utf-?8|iso-8859-|ascii$|euc|Mac|cp12|jis0201-raw|big5|visciii)/;
		return $crlf_safe ? ":unix:crlf:encoding($encoding)" : ":raw:encoding($encoding):crlf";
	}
	else {
		return ":raw:encoding($encoding)";
	}
}

sub read_text {
	my ($filename, $encoding, %options) = @_;
	$encoding ||= 'utf-8';
	my $layer = _text_layers($encoding, \%options);
	return read_binary($filename, %options) if $layer eq ':raw';

	open my $fh, "<$layer", $filename or croak "Couldn't open $filename: $!";
	my $buf_ref = exists $options{buf_ref} ? $options{buf_ref} : \my $buf;
	${$buf_ref} = do { local $/; <$fh> };
	close $fh;
	return if not defined wantarray or $options{buf_ref};
	return $buf;
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
	return $options{array_ref} ? \@buf : @buf;
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

# ABSTRACT: A simple, sane and efficient file slurper

=head1 SYNOPSIS

 use File::Slurp::Sane 'read_text';
 my $content = read_text($filename);

=head1 DESCRIPTION

This module provides functions for fast and correct slurping and spewing. All functions are optionally exported.

=func read_text($filename, $encoding, %options)

Reads file C<$filename> into a scalar and decodes it from C<$encoding> (which defaults to UTF-8). By default it returns this scalar. Can optionally take these named arguments:

=over 4

=item * buf_ref

Pass a reference to a scalar to read the file into, instead of returning it by value. This has performance benefits.

=item * crlf

This forces crlf translation on the input. The default for this argument is platform specific.

=back

=item read_binary

Reads file C<$filename> into a scalar without any decoding or transformation. By default it returns this scalar. Can optionally take this named argument:

=over 4

=item * buf_ref

Pass a reference to a scalar to read the file into, instead of returning it by value. This has performance benefits.

=back

=func read_lines($filename, $encoding, %options)

Reads file C<$filename> into a list/array after decoding from C<$encoding>. By default it returns this list. Can optionally take these named arguments:

=over 4

=item * array_ref

Pass a reference to an array to read the lines into, instead of returning them by value. This has performance benefits.

=item * chomp

C<chomp> the lines.

=back

=func read_dir($dirname, %options)

Open C<dirname> and return all entries except C<.> and C<..>. Can optionally take this named argument:

=over 4

=item * prefix

This will prepend C<$dir> to the entries

=back

=head1 SEE ALSO

=over 4

=item * L<Path::Tiny>

A minimalistic abstraction not only around IO but also paths.

=item * L<File::Slurp>

Another file slurping tool.

=back

=cut
