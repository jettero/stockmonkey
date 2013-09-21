# vi:set syntax=perl:

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Math::Business',
    DISTNAME     => 'stockmonkey',
    PREREQ_PM    => { constant => 1.05 },
    VERSION_FROM => 'Business.pm',

    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
        (MIN_PERL_VERSION => 5.006001,
            META_MERGE => {
                keywords => [qw(ATR bollinger-bands CCI DMI EMA HMA MACD RSI SMA WMU ParabolicSAR LaguerreFilter)],
                resources=> {
                    repository => 'http://github.com/jettero/stockmonkey',
                },
            },

        LICENSE	=> 'LGPL',
    ) : ()),
);
