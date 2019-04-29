package BuildDb::PatientList;
use Moose;

has 'patients' => (
    traits => [qw(Array)],
    is => 'rw',
    isa => 'ArrayRef[BuildDb::Patient]',
    default => sub {[]},
    handles => {
        all_patients     => 'elements',
        add_patient      => 'push',
        map_patients     => 'map',
        filter_patients  => 'grep',
        find_patient     => 'first',
        get_patient      => 'get',
        join_patients    => 'join',
        count_patients   => 'count',
        has_patients     => 'count',
        has_no_patients  => 'is_empty',
        sorted_patients  => 'sort',
    }
);
 
1;