package BuildDb::TransactionList;
use Moose;

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