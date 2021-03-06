use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Data::SUID',
    AUTHOR             => 'Iain Campbell <cpanic@cpan.org>',
    VERSION_FROM       => 'lib/Data/SUID.pm',
    ABSTRACT_FROM      => 'lib/Data/SUID.pm',
    LICENSE            => 'gpl_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'threads'                => 0,
        'threads::shared'        => 0,
        'Crypt::Random'          => 0,
        'Exporter'               => 0,
        'Net::Address::Ethernet' => 0,
        'Math::BigInt'           => 0,
        'Readonly'               => 0,
        'namespace::clean'       => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/cpanic/Data-SUID.git',
                web  => 'https://github.com/cpanic/Data-SUID',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Data-SUID-*' },
);
