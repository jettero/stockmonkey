# vi:set syntax=perl:

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Math::Business',
    DISTNAME  => 'stockmonkey',
    VERSION   => '2.11',
    PREREQ_PM => { constant => 1.05 },
);
