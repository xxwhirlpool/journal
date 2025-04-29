#!/usr/bin/perl
#
# DW::BlobStore::S3
#
# Library for storing blobs in S3.
#
# Authors:
#     Mark Smith <mark@dreamwidth.org>
#
# Copyright (c) 2016-2017 by Dreamwidth Studios, LLC.
#
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself.  For a copy of the license, please reference
# 'perldoc perlartistic' or 'perldoc perlgpl'.
#

package DW::BlobStore::S3;

use strict;
use v5.10;
use Log::Log4perl;
my $log = Log::Log4perl->get_logger(__PACKAGE__);

use Digest::MD5 qw/ md5_hex /;
use Paws;
use Paws::Credential::Environment;
use Env;

sub type { 's3' }

my $region = $ENV{'AWS_DEFAULT_REGION'};
my $endpoint = $ENV{'AWS_ENDPOINT_URL'};
my $bucket = $ENV{'AWS_BUCKET'};

my $creds = Paws::Credential::Environment->new;
my $auth = Paws->service('S3', bucket => $bucket, credentials => $creds, endpoint => $endpoint, region => $region);

sub init {
    my ( $class, %args ) = @_;

    foreach my $required (qw/ access_key secret_key region endpoint prefix bucket /) {
        $log->logcroak( 'S3 configuration must include config: ', $required )
            unless exists $args{$required};
    }

    $log->logcroak('Prefix does not match required regex: [a-zA-Z0-9_-]+$.')
        if defined $args{prefix} && $args{prefix} !~ /^[a-zA-Z0-9_-]+$/;

    my $paws = Paws->new(
        config => {
            region => $args{region},
            endpoint => $args{endpoint},
            bucket => $args{bucket},
        },
    ) or $log->logcroak('Failed to initialize Paws object.');
    
    my $creds = Paws::Credential::Environment->new;
    
    my $region = $ENV{'AWS_DEFAULT_REGION'};
    my $endpoint = $ENV{'AWS_ENDPOINT_URL'};
    my $bucket = $ENV{'AWS_BUCKET'};
    
    my $auth = Paws->service('S3', bucket => $bucket, credentials => $creds, endpoint => $endpoint, region => $region)
        or $log->logcroak('Failed to initialize Paws::S3 object.');

    $log->debug("Initializing blobstore for S3");
    my $self = {
        s3     => $auth,
        bucket => $args{bucket},
        prefix => $args{prefix},
    };
    return bless $self, $class;
}

sub get_location_for_key {
    my ( $self, $namespace, $key ) = @_;
    # my $creds = Paws::Credential::Explicit->new( access_key => "RXCsajgYYTNHT2C4kCjG", secret_key => "ekiHbULDIvXo95AnjbiZqfRH5CZLtZMj77cclYgx" );
    # my $s3 = Paws->service('S3', bucket => "love4eva", credentials => $creds, endpoint => "http://minio:9000", region => "us-east-1");

    # Hash the key, we create two layers of directory structure so the files
    # spread across 256^2 directories
    my $hash = md5_hex($key);

    # Create the fully qualified path including optional configured prefix
    my $fqfn =
          ( defined $self->{prefix} ? $self->{prefix} . '/' : '' )
        . $namespace . '/'
        . substr( $hash, 0, 2 ) . '/'
        . substr( $hash, 2, 2 ) . '/'
        . $hash;
    $log->debug("($namespace, $key) => $fqfn");
    return $fqfn;
}

sub store {
    my ( $self, $namespace, $key, $blobref ) = @_;
    # my $creds = Paws::Credential::Explicit->new( access_key => "RXCsajgYYTNHT2C4kCjG", secret_key => "ekiHbULDIvXo95AnjbiZqfRH5CZLtZMj77cclYgx" );
    # my $s3 = Paws->service('S3', bucket => "love4eva", credentials => $creds, endpoint => "http://minio:9000", region => "us-east-1");
    $log->logcroak('Unable to store empty file.')
        unless defined $$blobref && length $$blobref;
    my $fqfn = $self->get_location_for_key( $namespace, $key );

    my $res = eval {
        $auth->PutObject(
            Bucket => $self->{bucket},
            Key    => $fqfn,
            Body   => $$blobref,
        );
    };
    if ( $@ && $@->isa('Paws::Exception') ) {
        $log->error( "Failed to store to ( $namespace, $key ): " . $@->message );
        return 0;
    }

    $log->debug( "Wrote ", length $$blobref, " bytes to: $fqfn" );
    return 1;
}

sub exists {
    my ( $self, $namespace, $key ) = @_;
    my $fqfn = $self->get_location_for_key( $namespace, $key );

    my $res = eval { $auth->HeadObject( Bucket => $self->{bucket}, Key => $fqfn, ) };
    if ( $@ && $@->isa('Paws::Exception') ) {
        $log->error( "Failed to check exists on ( $namespace, $key ): ", $@->message );
        return 0;
    }

    $log->debug( 'Found path exists in S3: ', $fqfn );
    return 1;
}

sub retrieve {
    my ( $self, $namespace, $key ) = @_;
    my $fqfn = $self->get_location_for_key( $namespace, $key );

    my $res = eval { $auth->GetObject( Bucket => $self->{bucket}, Key => $fqfn, ) };
    if ( $@ && $@->isa('Paws::Exception') ) {
        $log->error( "Failed to retrieve from ( $namespace, $key ): " . $@->message );
        return undef;
    }
    return \$res->Body;
}

sub delete {
    my ( $self, $namespace, $key ) = @_;
    my $fqfn = $self->get_location_for_key( $namespace, $key );

    my $res = eval { $auth->DeleteObject( Bucket => $self->{bucket}, Key => $fqfn, ) };
    if ( $@ && $@->isa('Paws::Exception') ) {
        $log->error( "Failed to delete ( $namespace, $key ): ", $@->message );
        return 0;
    }

    $log->debug( 'Deleted path from S3: ', $fqfn );
    return 1;
}

1;
