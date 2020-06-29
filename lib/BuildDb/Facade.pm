package BuildDb::Facade;

use strict;
use DBI;

use BuildDb::Config qw(
    $project_root
    $log_file
    $driver
    $database
    $dsn
    $username
    $password
);

use BuildDb::Logger qw(
    $logger
);

#my @ISA = qw(Exporter);
use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(
create_patients_table
create_transactions_table
insert_patients
insert_transactions
);

sub create_patients_table {    
    my $dbh = DBI->connect($dsn, $username, $password, { RaiseError => 1 }) or $logger->logdie($DBI::errstr);
    
    $logger->debug("Successfully connected to database");
    
    my $stmt = qq(CREATE TABLE IF NOT EXISTS patients (
            id INTEGER PRIMARY KEY  AUTOINCREMENT,
            first_name          TEXT    NOT NULL,
            last_name           TEXT    NOT NULL,
            email               TEXT    NOT NULL,
            account_number      TEXT    NOT NULL,
            street_address      TEXT    NOT NULL,
            city                TEXT    NOT NULL,
            state               TEXT    NOT NULL,
            zip_code            TEXT    NOT NULL
        );
    );
    
    my $rv = $dbh->do($stmt);
    if($rv < 0) {
        $logger->error($DBI::errstr);
    } else {
        $logger->debug("Patients table created or exists");
    }
    
    $logger->debug("Disconnecting from database");
    $dbh->disconnect();
    $logger->debug("Successfully disconnected from database");
}

sub create_transactions_table {
    my $dbh = DBI->connect($dsn, $username, $password, { RaiseError => 1 }) or $logger->logdie($DBI::errstr);
        
    $logger->debug("Successfully connected to database");
    
    my $stmt = qq(CREATE TABLE IF NOT EXISTS transactions (
            id INTEGER PRIMARY KEY  AUTOINCREMENT,
            transaction_id          TEXT    NOT NULL,
            transaction_description TEXT    NOT NULL,
            transaction_amount      TEXT    NOT NULL,
            transaction_date        TEXT    NOT NULL,
            patient_id              INTEGER NOT NULL,
                FOREIGN KEY (patient_id) REFERENCES patients(id)
        );
    );
    
    my $rv = $dbh->do($stmt);
    if($rv < 0) {
        $logger->error($DBI::errstr);
    } else {
        $logger->debug("Transactions table created or exists");
    }
    
    $logger->debug("Disconnecting from database");
    $dbh->disconnect();
    $logger->debug("Successfully disconnected from database");
}

sub insert_patients {
    my $self = shift;
    my $patient_list = shift;
    
    my @patient_ids = ();
    
    my $dbh = DBI->connect($dsn, $username, $password, { RaiseError => 1 }) or $logger->logdie($DBI::errstr);
        
    $logger->debug("Successfully connected to database");
    
    my $id;
    my $first_name;
    my $last_name;
    my $email;
    my $account_number;
    my $street_address;
    my $city;
    my $state;
    my $zip;
    
    $logger->debug("Inserting patients");
    foreach my $patient (@{$patient_list->patients}) {
        $first_name = $patient->firstName;
        $last_name = $patient->lastName;
        $email = $patient->email;
        $account_number = $patient->accountNumber;
        $street_address = $patient->streetAddress;
        $city = $patient->city;
        $state = $patient->patientState;
        $zip = $patient->zip;

        my $stmt = qq(INSERT INTO patients (first_name, last_name, email, account_number, street_address, city, state, zip_code)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?));
        my $sth = $dbh->prepare($stmt);
        my $rc = $sth->execute($first_name, $last_name, $email, $account_number, $street_address, $city, $state, $zip) or $logger->logdie($DBI::errstr);
        
        $id = $dbh->sqlite_last_insert_rowid;
        push @patient_ids, $id;
        
        # TODO add id to patient object

        $logger->debug("Successfully inserted patient {id: $id, first name: $first_name, last name: $last_name}");
    }
    $logger->debug("Successfully inserted all patients");
    
    $logger->debug("Disconnecting from database");
    $dbh->disconnect();
    $logger->debug("Successfully disconnected from database");
    
    return @patient_ids;
}

sub insert_transactions {
    my $self = shift;
    my $transaction_list = shift;
    
    my $dbh = DBI->connect($dsn, $username, $password, { RaiseError => 1 }) or $logger->logdie($DBI::errstr);
        
    $logger->debug("Successfully connected to database");
    
    my $id;
    my $transaction_id;
    my $patient_id;
    my $transaction_description;
    my $transaction_amount;
    my $transaction_date;
    
    $logger->debug("Inserting transactions");
    foreach my $transaction (@{$transaction_list->transactions}) {
        $transaction_id = $transaction->transactionId;
        $patient_id = $transaction->patientId;
        $transaction_description = $transaction->transactionDescription;
        $transaction_amount = $transaction->transactionAmount;
        $transaction_date = $transaction->transactionDate;

        my $stmt = qq(INSERT INTO transactions (transaction_id, transaction_description, transaction_amount, transaction_date, patient_id)
               VALUES (?, ?, ?, ?, ?));
        my $sth = $dbh->prepare($stmt);
        my $rc = $sth->execute($transaction_id, $transaction_description, $transaction_amount, $transaction_date, $patient_id) or $logger->logdie($DBI::errstr);
        
        $id = $dbh->sqlite_last_insert_rowid;
        
        # TODO add id to transaction object

        $logger->debug("Successfully inserted transaction {id: $id, transaction id: $transaction_id, transaction description: $transaction_description}");
    }
    $logger->debug("Successfully inserted all transactions");
    
    $logger->debug("Disconnecting from database");
    $dbh->disconnect();
    $logger->debug("Successfully disconnected from database");
}

1;
