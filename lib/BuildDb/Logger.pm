package BuildDb::Logger;

# Simple logging config
use Log::Log4perl qw(:easy);

use BuildDb::Config qw(
    $project_root
    $log_file
    $minimal_log_level
);

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(
    $logger
);

our $logger;

init_variables();

sub init_variables {
    Log::Log4perl->easy_init(
        {
            file => ">> " . $project_root . $log_file,
            level => $minimal_log_level
        },
        
        {
            file  => "STDERR",
            level => $minimal_log_level
        }
    );

    $logger = Log::Log4perl->get_logger();
}

1;