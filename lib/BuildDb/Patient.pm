package BuildDb::Patient;
use Moose;

# id created by the database on insertion
has 'id' => (isa => 'Str', is => 'rw');
has 'firstName' => (isa => 'Str', is => 'rw');
has 'lastName' => (isa => 'Str', is => 'rw');
has 'email' => (isa => 'Str', is => 'rw');
has 'accountNumber' => (isa => 'Str', is => 'rw');
has 'streetAddress' => (isa => 'Str', is => 'rw');
has 'city' => (isa => 'Str', is => 'rw');
has 'patientState' => (isa => 'Str', is => 'rw');
has 'zip' => (isa => 'Str', is => 'rw');

has 'transactions' => (
    traits => [qw(Array)],
    is => 'rw',
    isa => 'ArrayRef[BuildDb::Transaction]',
    default => sub {[]},
    handles => {
        all_transactions     => 'elements',
        add_transaction      => 'push',
        map_transactions     => 'map',
        filter_transactions  => 'grep',
        find_transaction     => 'first',
        get_transaction      => 'get',
        join_transactions    => 'join',
        count_transactions   => 'count',
        has_transactions     => 'count',
        has_no_transactions  => 'is_empty',
        sorted_transactions  => 'sort',
    }
);
 
1;