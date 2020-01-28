# use strict;
use diagnostics;

use Text::CSV;
use IO::File;

use Config::Simple;

# global variables
# my %Config;
# Config::Simple->import_from('app.ini', \%Config);
my $cfg = new Config::Simple('app.ini');

my $projectRoot = $cfg->param("app.project_root");
my $logFile = $cfg->param("app.log_file");
my $projectLib = $cfg->param("app.project_lib");
my $patientFile = $cfg->param("app.patient_file");
my $transactionFile = $cfg->param("app.transaction_file");

# global constants
# use constant PROJECT_ROOT => projectRoot;
# use constant LOG_FILE => logFile;
# use constant PROJECT_LIB => projectLib;
# use constant PATIENT_FILE => patientFile;
# use constant TRANSACTION_FILE => transactionFile;

# use constant PROJECT_ROOT => $cfg->param("app.project_root");
# use constant LOG_FILE => $cfg->param("app.log_file");
# use constant PROJECT_LIB => $cfg->param("app.project_lib");
# use constant PATIENT_FILE => $cfg->param("app.patient_file");
# use constant TRANSACTION_FILE => $cfg->param("app.transaction_file");

# Simple logging config
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init(
    {
        # file  => ">> C:/Users/jfigueroa/projects/perl/BuildDatabase/log/build-db.log",
        file => ">> " . $projectRoot . $logFile,
        level => $DEBUG
    },
    
    {
        file  => "STDERR",
        level => $DEBUG
    }
);

# Directory with my packages
# use lib "/home/jason/eclipse-workspace/perl/BuildDatabase/lib/";
use lib "/vagrant/BuildDatabase/lib/";
# use lib projectRoot . projectLib;

# My packages
use BuildDb::Patient;
use BuildDb::PatientList;
use BuildDb::Facade;
use BuildDb::TransactionList;
use BuildDb::Transaction;

main();

sub main {
    # my %Config;
    # Config::Simple->import_from('app.ini', \%Config);
    # my $cfg = new Config::Simple('app.ini');

    # my $projectRoot = $cfg->param("app.project_root");
    # my $logFile = $cfg->param("app.log_file");
    # my $projectLib = $cfg->param("app.project_lib");
    # my $patientFile = $cfg->param("app.patient_file");
    # my $transactionFile = $cfg->param("app.transaction_file");

    DEBUG("Beginning program execution");
    
    my $patientCsv = Text::CSV->new({ sep_char => ',' });
     
    # Following is for command line args, I've not tested it
    #my $file = $ARGV[0] or die "Need to get CSV file on the command line\n";
    
    # Deactivate the following if using command line args
    # my $patientFile = "/home/jason/eclipse-workspace/perl/BuildDatabase/data/input/PATIENT_DATA.csv";
    my $patientFile = $projectRoot . $patientFile;
    
    # Using LOGDIE instead of die
    open(my $patientData, '<:encoding(utf8)', $patientFile) or LOGDIE "Could not open '$patientFile' $!\n";
    
    my $headers = <$patientData>;
    
    chomp $headers;
    
    my @headerFields;
    if ($patientCsv->parse($headers)) {
        @headerFields = $patientCsv->fields();
    }
    
    my @validPatientHeaders = (
        'first_name',
        'last_name',
        'email',
        'account_number',
        'street_address',
        'city',
        'state',
        'zip_code'
    );
    
    if (!valid_headers(\@validPatientHeaders, \@headerFields)) {
        LOGDIE "invalid headers, valid headers in any order [first_name, last_name, email, account_number, street_address, city, state, zip_code]\n";
    }
    
    my $headerIndex = 0;
    my %headerHash;
    
    # Capturing header indexes from the data
    for my $header (@headerFields) {
        $headerHash{$header} = $headerIndex++;
    }
    
    # Creating tables
    BuildDb::Facade->create_patients_table();
    BuildDb::Facade->create_transactions_table();
    
    # PatientList Object
    my $patientList = build_patient_list($patientCsv, $patientData, \%headerHash);

    # For random assignment of patient ids to transactions, this relationship is arbitrary and created on execution
    my @patientIds = BuildDb::Facade->insert_patients($patientList);
    
    my $transactionCsv = Text::CSV->new({ sep_char => ',' });
    
    # Deactivate the following if using command line args
    # my $transactionFile = "/home/jason/eclipse-workspace/perl/BuildDatabase/data/input/TRANSACTION_DATA.csv";
    my $transactionFile = $projectRoot . $transactionFile;
    
    # Using LOGDIE instead of die
    open(my $transactionData, '<', $transactionFile) or LOGDIE "Could not open '$transactionFile' $!\n";
    
    my $transactionHeaders = <$transactionData>;
    
    chomp $transactionHeaders;
    
    my @transactionHeaderFields;
    if ($transactionCsv->parse($transactionHeaders)) {
        @transactionHeaderFields = $transactionCsv->fields();
    }
    
    my $transactionHeaderIndex = 0;
    my %transactionHeaderHash;
    for my $header (@transactionHeaderFields) {
        $transactionHeaderHash{$header} = $transactionHeaderIndex++;
    }
    
    # TransactionList Object
    my $transactionList = build_transaction_list($transactionCsv, $transactionData, \%transactionHeaderHash, \@patientIds);
    
    BuildDb::Facade->insert_transactions($transactionList);

    my $x = 1;
    DEBUG("Exiting program");
}

# Parameter(s):
#   patient csv ... object?
#   patient data ... object?
#   refernce to headers hash containing indexes for valid headers
sub build_patient_list {
    my $patientCsv = shift;
    my $patientData = shift;
    
    my $headersHashReference = shift;
    
    my %headersHash = %{$headersHashReference};
    
    my $patientList = BuildDb::PatientList->new();
    while (my $line = <$patientData>) {
        chomp $line;  
     
        if ($patientCsv->parse($line)) {
     
            my @fields = $patientCsv->fields();
            
            # Patient Object
            my $patient = BuildDb::Patient->new(
                    firstName => $fields[$headersHash{'first_name'}],
                    lastName => $fields[$headersHash{'last_name'}],
                    email => $fields[$headersHash{'email'}],
                    accountNumber => $fields[$headersHash{'account_number'}],
                    streetAddress => $fields[$headersHash{'street_address'}],
                    city => $fields[$headersHash{'city'}],
                    patientState => $fields[$headersHash{'state'}],
                    zip => $fields[$headersHash{'zip_code'}]
                );        
            
            $patientList->add_patient($patient);
     
        } else {
            LOGDIE "build_patient_list subroutine could not parse line: $line\n";
        }
    }
    
    return $patientList;
}

# Parameter(s):
#   transaction csv ... object?
#   transaction data ... object?
#   reference to headers hash containing indexes for valid headers
#   reference to array containing all patient ids
sub build_transaction_list {
    my $transactionCsv = shift;
    my $transactionData = shift;
    
    my $headersHashReference = shift;
    my $patientIdsReference = shift;
    
    my %headersHash = %{$headersHashReference};
    my @patientIds = @{$patientIdsReference};
    
    my $transactionList = BuildDb::TransactionList->new();
    while (my $line = <$transactionData>) {
        chomp $line;  
     
        if ($transactionCsv->parse($line)) {
     
            my @fields = $transactionCsv->fields();
            
            # For randomly assigning transactions to existing patient ids
            my $randomNumber = int(rand($patientIds[$#patientIds]));
            
            # Transaction Object
            my $transaction = BuildDb::Transaction->new(
                    transactionId => $fields[$headersHash{'transaction_id'}],
                    patientId => $randomNumber,
                    transactionDescription => $fields[$headersHash{'transaction_description'}],
                    transactionAmount => $fields[$headersHash{'transaction_amount'}],
                    transactionDate => $fields[$headersHash{'transaction_date'}]
                );        
            
            $transactionList->add_transaction($transaction);
     
        } else {
            LOGDIE "build_transaction_list subroutine could not parse line: $line\n";
        }
    }
    
    return $transactionList;
}

# Parameter(s):
#   Array of valid headers
#   Array of headers from data
sub valid_headers {
    my $validHeadersReference = shift;
    my $headersReference = shift;
    
    my @validHeaders = @{$validHeadersReference};
    my @headers = @{$headersReference};
    
    my $validHeadersCount = @validHeaders;
    my $headersCount = @headers;
    
    # if arrays are not of equal length
    if ($validHeadersCount ne $headersCount) {
        return 0;
    }
    
    for my $validHeader(@validHeaders) {
        # If validHeader not found in headers array
        if ( grep { $_ eq $validHeader} @headers ) {
            next;
        }
        
        else {
            return 0;
        }
    }
    
    return 1;
}
