package BuildDb::Transaction;
use Moose;

has 'transactionId' => (isa => 'Str', is => 'rw');
has 'patientId' => (isa => 'Str', is => 'rw');
has 'transactionDescription' => (isa => 'Str', is => 'rw');
has 'transactionAmount' => (isa => 'Str', is => 'rw');
has 'transactionDate' => (isa => 'Str', is => 'rw');
 
1;