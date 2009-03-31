# vi:set syntax=perl:

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Math::Business',
    DISTNAME  => 'stockmonkey',
    VERSION   => '2.9013',
    PREREQ_PM => { constant => 1.05 },

    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
        (MIN_PERL_VERSION => 5.008,
            META_MERGE => {
                keywords => [qw(ATR bollinger-bands DMI EMA HMA MACD RSI SMA WMU ParabolicSAR LaguerreFilter)],
                resources=> {
                    repository => 'http://github.com/jettero/stockmonkey/tree',
                },
            },

        LICENSE	=> 'lgpl2',
    ) : ()),
);
