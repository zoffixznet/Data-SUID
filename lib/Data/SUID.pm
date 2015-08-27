package Data::SUID;

# Copyright (c) 2014-2015 Iain Campbell. All rights reserved.
#
# This work may be used and modified freely, but I ask that the copyright
# notice remain attached to the file. You may modify this module as you
# wish, but if you redistribute a modified version, please attach a note
# listing the modifications you have made.

=pod

=encoding utf-8

=head1 NAME

Data::SUID - Generates thread-safe sequential unique ids 

=head1 SYNOPSIS

    use Data::SUID 'suid';              # Or use ':all' tag
    use Data::Dumper;
    
    $Data::Dumper::Indent = 0;
    $Data::Dumper::Terse  = 1;
    
    my $suid = suid();                  # Old school, or ...
    my $suid = Data::SUID->new();       # Do it OOP style
    
    print $suid->hex                    # 55de233819d51b1a8a67e0ac
    print $suid->dec                    # 26574773684474770905501261996
    print $suid->uuencode               # ,5=XC.!G5&QJ*9^"L
    print $suid->binary                 # 12 bytes of unreadable gibberish
    print $suid                         # 55de233819d51b1a8a67e0ac
    

    # Use the hex, dec, uuencode and binary methods as fire-and-forget
    # constructors, if you prefer:    
    
    my $suid_hex = suid->hex;           # If you just want the goodies
    
=head1 DESCRIPTION

Use this package to generate thread-safe 12-byte sequential unique ids 
modeled upon the MongoDB BSON ObjectId. Unlike traditional GUIDs, these
some somewhat more index-friendly and reasonably suited for use as 
primary keys within database tables. They are guaranteed to have a high
level of uniqueness, given that they contain a timestamp, a host identifier
and an incremented sequence number.
  
=cut

use strict;
use warnings;
use threads;
use threads::shared;
use Crypt::Random          ();
use Exporter               ();
use Net::Address::Ethernet ();
use Math::BigInt try => 'GMP';
use Readonly;
use namespace::clean;
use overload '""' => 'hex';

our $VERSION = '1.000001';
$VERSION = eval($VERSION);

our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(suid);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

=head1 METHODS

=over 2

=item B<new>

Generates a new SUID object.

    my $suid = Data::SUID->new();

=back

=cut

sub new
{
    my ($class) = @_;
    $class = $class || __PACKAGE__;
    my $time = time();
    my $host = &_machine_ident;
    Readonly my $id => sprintf( '%08x%s%04x%s', $time, $host, $$, &_count ); # SUID value cannot be modified.
    return bless( \$id, $class );
}

=over 2

=item B<uuencode>

Returns the SUID value as a 24-character hexadecimal string.

The SUID object's stringification operation has been overloaded to give this value, too.

=back

=cut

sub hex
{
    my ($self) = @_;
    $self = &new unless ref($self);
    return $$self;
}

=over 2

=item B<uuencode>

Returns the SUID value as a big integer.

=back

=cut

sub dec
{
    my ($self) = @_;
    $self = &new unless ref($self);
    return Math::BigInt->new( '0x' . $$self );
}

=over 2

=item B<uuencode>

Returns the SUID value as a UUENCODED string.

=back

=cut

sub uuencode
{
    my ($self) = @_;
    $self = &new unless ref($self);
    return pack('u', pack('H*', $$self));
}

=over 2

=item B<binary>

Returns the SUID value as 12 bytes of binary data.

=back

=cut

sub binary
{
    use bytes;
    my ($self) = @_;
    $self = &new unless ref($self);
    return pack('H*', $$self);
}

=head1 EXPORTED FUNCTIONS

=over 2

=item B<suid>

Generates a new SUID object.

    my $suid = suid();

=back

=cut

sub suid
{
    return __PACKAGE__->new(@_);
}

{
    my @ident : shared;
    my $ident : shared;

    lock @ident;
    lock $ident;

    @ident = +( map 0 + $_, Net::Address::Ethernet::get_address() )[ 3, 4, 5 ];    # Don't want the 24-bit OUID!
    $ident = sprintf( '%02x%02x%02x', @ident );

    sub _machine_ident
    {
        return wantarray ? @ident : $ident;
    }
}

{
    my $count_width    = 24;
    my $count_mask     = 2**$count_width - 1;
    my $count_format   = '%0' . int( $count_width / 4 ) . 'x';
    my $count : shared = undef;

    sub _reset_count
    {
        my ( $class, $value ) = @_;

        lock $count;
        $count = undef;

        if ( defined $value )
        {
            $count = $count_mask & ( 0 + abs($value) );
        }

        unless ( defined $count )
        {
            my $random = Crypt::Random::makerandom( Strength => 1, Uniform => 1, Size => $count_width );
            $count = "$random";    # Can't share $random between threads, so coerce as string and assign to count
        }

        return $class;
    }

    sub _count
    {
        &_reset_count unless defined $count;
        my $result = sprintf( $count_format, $count );
        lock $count;
        $count = $count_mask & ( 1 + $count );
        return $result;
    }
}

1;

=head1 REPOSITORY

L<https://github.com/cpanic/Data-SUID>

=head1 BUG REPORTS

Please report any bugs to L<http://rt.cpan.org/>

=head1 AUTHOR

Iain Campbell <cpanic@cpan.org>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2012-2015 by Iain Campbell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
