use strict;
use diagnostics;

use Text::CSV;
use IO::File;

use BuildDb::Config qw(
    $project_root
    $log_file
    $patient_file
    $transaction_file
);

use BuildDb::Logger qw(
    $logger
);

use BuildDb::Patient;
use BuildDb::PatientList;
use BuildDb::Facade;
use BuildDb::TransactionList;
use BuildDb::Transaction;

main();

sub main {
    $logger->debug("Beginning program execution");
    
    my $patient_csv = Text::CSV->new({ sep_char => ',' });
     
    # Following is for command line args, I've not tested it
    #my $file = $ARGV[0] or die "Need to get CSV file on the command line\n";
    
    # Deactivate the following if using command line args
    my $patient_file = $project_root . $patient_file;
    
    # Using logdie instead of die
    open(my $patient_data, '<:encoding(utf8)', $patient_file) or $logger->logdie("Could not open '$patient_file' $!\n");
    
    my $headers = <$patient_data>;
    
    chomp $headers;
    
    my @header_fields;
    if ($patient_csv->parse($headers)) {
        @header_fields = $patient_csv->fields();
    }
    
    my @valid_patient_headers = (
        'first_name',
        'last_name',
        'email',
        'account_number',
        'street_address',
        'city',
        'state',
        'zip_code'
    );
    
    if (!valid_headers(\@valid_patient_headers, \@header_fields)) {
        $logger->logdie("invalid headers, valid headers in any order [first_name, last_name, email, account_number, street_address, city, state, zip_code]\n");
    }
    
    my $header_index = 0;
    my %header_hash;
    
    # Capturing header indexes from the data
    for my $header (@header_fields) {
        $header_hash{$header} = $header_index++;
    }
    
    # Creating tables
    BuildDb::Facade->create_patients_table();
    BuildDb::Facade->create_transactions_table();
    
    # PatientList Object
    my $patient_list = build_patient_list($patient_csv, $patient_data, \%header_hash);

    # For random assignment of patient ids to transactions, this relationship is arbitrary and created on execution
    my @patient_ids = BuildDb::Facade->insert_patients($patient_list);
    
    my $transaction_csv = Text::CSV->new({ sep_char => ',' });
    
    # Deactivate the following if using command line args
    # my $transaction_file = "/home/jason/eclipse-workspace/perl/BuildDatabase/data/input/TRANSACTION_DATA.csv";
    my $transaction_file = $project_root . $transaction_file;
    
    # Using LOGDIE instead of die
    open(my $transaction_data, '<', $transaction_file) or $logger->logdie("Could not open '$transaction_file' $!\n");
    
    my $transaction_headers = <$transaction_data>;
    
    chomp $transaction_headers;
    
    my @transaction_header_fields;
    if ($transaction_csv->parse($transaction_headers)) {
        @transaction_header_fields = $transaction_csv->fields();
    }
    
    my $transaction_header_index = 0;
    my %transaction_header_hash;
    for my $header (@transaction_header_fields) {
        $transaction_header_hash{$header} = $transaction_header_index++;
    }
    
    # TransactionList Object
    my $transaction_list = build_transaction_list($transaction_csv, $transaction_data, \%transaction_header_hash, \@patient_ids);
    
    BuildDb::Facade->insert_transactions($transaction_list);

    my $x = 1;
    $logger->debug("Exiting program");
}

# Parameter(s):
#   patient csv ... Text::CSV=HASH (type)
#   patient data ... GLOB (type)
#   reference to headers hash containing indexes for valid headers
sub build_patient_list {
    my $patient_csv = shift;
    my $patient_data = shift;
    
    my $headers_hash_reference = shift;
    
    my %headers_hash = %{$headers_hash_reference};
    
    my $patient_list = BuildDb::PatientList->new();
    while (my $line = <$patient_data>) {
        chomp $line;  
     
        if ($patient_csv->parse($line)) {
     
            my @fields = $patient_csv->fields();
            
            # Patient Object
            my $patient = BuildDb::Patient->new(
                    firstName => $fields[$headers_hash{'first_name'}],
                    lastName => $fields[$headers_hash{'last_name'}],
                    email => $fields[$headers_hash{'email'}],
                    accountNumber => $fields[$headers_hash{'account_number'}],
                    streetAddress => $fields[$headers_hash{'street_address'}],
                    city => $fields[$headers_hash{'city'}],
                    patientState => $fields[$headers_hash{'state'}],
                    zip => $fields[$headers_hash{'zip_code'}]
                );        
            
            $patient_list->add_patient($patient);
     
        } else {
            $logger->logdie("build_patient_list subroutine could not parse line: $line\n");
        }
    }
    
    return $patient_list;
}

# Parameter(s):
#   transaction csv ... object?
#   transaction data ... object?
#   reference to headers hash containing indexes for valid headers
#   reference to array containing all patient ids
sub build_transaction_list {
    my $transaction_csv = shift;
    my $transaction_data = shift;
    
    my $headers_hash_reference = shift;
    my $patient_ids_reference = shift;
    
    my %headers_hash = %{$headers_hash_reference};
    my @patient_ids = @{$patient_ids_reference};
    
    my $transaction_list = BuildDb::TransactionList->new();
    while (my $line = <$transaction_data>) {
        chomp $line;  
     
        if ($transaction_csv->parse($line)) {
     
            my @fields = $transaction_csv->fields();
            
            # For randomly assigning transactions to existing patient ids
            my $random_number = int(rand($patient_ids[$#patient_ids]));
            
            # Transaction Object
            my $transaction = BuildDb::Transaction->new(
                    transactionId => $fields[$headers_hash{'transaction_id'}],
                    patientId => $random_number,
                    transactionDescription => $fields[$headers_hash{'transaction_description'}],
                    transactionAmount => $fields[$headers_hash{'transaction_amount'}],
                    transactionDate => $fields[$headers_hash{'transaction_date'}]
                );        
            
            $transaction_list->add_transaction($transaction);
     
        } else {
            $logger->logdie("build_transaction_list subroutine could not parse line: $line\n");
        }
    }
    
    return $transaction_list;
}

# Parameter(s):
#   Array of valid headers
#   Array of headers from data
sub valid_headers {
    my $valid_headers_reference = shift;
    my $headers_reference = shift;
    
    my @valid_headers = @{$valid_headers_reference};
    my @headers = @{$headers_reference};
    
    my $valid_headers_count = @valid_headers;
    my $headers_count = @headers;
    
    # if arrays are not of equal length
    if ($valid_headers_count ne $headers_count) {
        return 0;
    }
    
    for my $valid_header(@valid_headers) {
        # If valid_header not found in headers array
        if ( grep { $_ eq $valid_header} @headers ) {
            next;
        }
        
        else {
            return 0;
        }
    }
    
    return 1;
}
