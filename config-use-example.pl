use strict;
use warnings;

use feature "say";

use Config::Simple;

sub main {
    my %Config;
    Config::Simple->import_from('app.ini', \%Config);
    my $cfg = new Config::Simple('app.ini');

    my $dsn = $cfg->param("sqlite.dsn");

    say $dsn;
}

main();