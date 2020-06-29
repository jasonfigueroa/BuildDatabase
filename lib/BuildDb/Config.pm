package BuildDb::Config;

use Cwd qw(cwd);
use Config::Simple;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(
    $project_root
    $log_file
    $patient_file
    $transaction_file
    $driver
    $database
    $dsn
    $username
    $password
    $minimal_log_level
);

our $project_root;
our $log_file;
our $patient_file;
our $transaction_file;
our $driver;
our $database;
our $dsn;
our $username;
our $password;
our $minimal_log_level;

my $cfg;

init_variables();

sub init_variables {
    $project_root = cwd;
    
    $cfg = new Config::Simple('app.ini');    
    
    $log_file = $cfg->param("app.log_file");
    $patient_file = $cfg->param("app.patient_file");
    $transaction_file = $cfg->param("app.transaction_file");

    $driver = $cfg->param("sqlite.driver");
    $database = $cfg->param("sqlite.database");
    $dsn = $cfg->param("sqlite.dsn");
    $username = $cfg->param("sqlite.user");
    $password = $cfg->param("sqlite.password");

    $minimal_log_level = $cfg->param("logger.minimal_log_level");
}

1;