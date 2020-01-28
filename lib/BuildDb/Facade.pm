# TODO $dbh = DBI->connect line is duplicated in multiple spots in this file, 
# maybe bring this to a higher scope to avoid duplication

package BuildDb::Facade;

use strict;
use DBI;
use Log::Log4perl qw(:easy);

# Simple logging config
Log::Log4perl->easy_init(
    {
        file  => ">> /vagrant/BuildDatabase/log/build-db.log",
        level => $DEBUG
    },
    
    {
        file  => "STDERR",
        level => $DEBUG
    }
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

sub init_variables {
    my %db_data;
    
    $db_data{'driver'} = "SQLite";
    $db_data{'database'} = "/vagrant/BuildDatabase/data/db/test.db";
    
    # dsn is a concatenated string comprised of the driver and the database name
    $db_data{'dsn'} = "DBI:$db_data{'driver'}:dbname=$db_data{'database'}";
    
    $db_data{'userid'} = "";
    $db_data{'password'} = "";
    
    return %db_data;
}

# TODO Check if table already exists
sub create_patients_table {    
    my %db_data = init_variables();    
    
    # connect has 4 variables: the constructed dsn, userid, password, RaiseError flag
    my $dbh = DBI->connect($db_data{'dsn'}, $db_data{'userid'} = "", $db_data{'password'} = "", { RaiseError => 1 })
        or LOGDIE $DBI::errstr;
        
    DEBUG("Successfully connected to database");
    
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
        ERROR($DBI::errstr);
    } else {
        DEBUG("Patients table created or exists");
    }
    
    DEBUG("Disconnecting from database");
    $dbh->disconnect();
    DEBUG("Successfully disconnected from database");
}

sub create_transactions_table {
    my %db_data = init_variables();    
    my $dbh = DBI->connect($db_data{'dsn'}, $db_data{'userid'} = "", $db_data{'password'} = "", { RaiseError => 1 })
        or LOGDIE $DBI::errstr;
        
    DEBUG("Successfully connected to database");
    
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
        ERROR($DBI::errstr);
    } else {
        DEBUG("Transactions table created or exists");
    }
    
    DEBUG("Disconnecting from database");
    $dbh->disconnect();
    DEBUG("Successfully disconnected from database");
}

sub insert_patients {
    my $self = shift;
    my $patientList = shift;
    
    my @patientIds = ();
    
    my %db_data = init_variables();    
    my $dbh = DBI->connect($db_data{'dsn'}, $db_data{'userid'} = "", $db_data{'password'} = "", { RaiseError => 1 })
        or LOGDIE $DBI::errstr;
        
    DEBUG("Successfully connected to database");
    
    my $id;
    my $firstName;
    my $lastName;
    my $email;
    my $accountNumber;
    my $streetAddress;
    my $city;
    my $state;
    my $zip;
    
    DEBUG("Inserting patients");
    foreach my $patient (@{$patientList->patients}) {
        $firstName = $patient->firstName;
        $lastName = $patient->lastName;
        $email = $patient->email;
        $accountNumber = $patient->accountNumber;
        $streetAddress = $patient->streetAddress;
        $city = $patient->city;
        $state = $patient->patientState;
        $zip = $patient->zip;

        my $stmt = qq(INSERT INTO patients (first_name, last_name, email, account_number, street_address, city, state, zip_code)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?));
        my $sth = $dbh->prepare($stmt);
        my $rc = $sth->execute($firstName, $lastName, $email, $accountNumber, $streetAddress, $city, $state, $zip) or LOGDIE $DBI::errstr;
        
        $id = $dbh->sqlite_last_insert_rowid;
        push @patientIds, $id;
        
        # TODO add id to patient object

        DEBUG("Successfully inserted patient {id: $id, first name: $firstName, last name: $lastName}");
    }
    DEBUG("Successfully inserted all patients");
    
    DEBUG("Disconnecting from database");
    $dbh->disconnect();
    DEBUG("Successfully disconnected from database");
    
    return @patientIds;
}

sub insert_transactions {
    my $self = shift;
    my $transactionList = shift;
    
    my %db_data = init_variables();    
    my $dbh = DBI->connect($db_data{'dsn'}, $db_data{'userid'} = "", $db_data{'password'} = "", { RaiseError => 1 })
        or LOGDIE $DBI::errstr;
        
    DEBUG("Successfully connected to database");
    
    my $id;
    my $transactionId;
    my $patientId;
    my $transactionDescription;
    my $transactionAmount;
    my $transactionDate;
    
    DEBUG("Inserting transactions");
    foreach my $transaction (@{$transactionList->transactions}) {
        $transactionId = $transaction->transactionId;
        $patientId = $transaction->patientId;
        $transactionDescription = $transaction->transactionDescription;
        $transactionAmount = $transaction->transactionAmount;
        $transactionDate = $transaction->transactionDate;

        my $stmt = qq(INSERT INTO transactions (transaction_id, transaction_description, transaction_amount, transaction_date, patient_id)
               VALUES (?, ?, ?, ?, ?));
        my $sth = $dbh->prepare($stmt);
        my $rc = $sth->execute($transactionId, $transactionDescription, $transactionAmount, $transactionDate, $patientId) or LOGDIE $DBI::errstr;
        
        $id = $dbh->sqlite_last_insert_rowid;
        
        # TODO add id to transaction object

        DEBUG("Successfully inserted transaction {id: $id, transaction id: $transactionId, transaction description: $transactionDescription}");
    }
    DEBUG("Successfully inserted all transactions");
    
    DEBUG("Disconnecting from database");
    $dbh->disconnect();
    DEBUG("Successfully disconnected from database");
}

1;
