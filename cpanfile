requires 'perl', '5.008001';
requires 'Algorithm::NaiveBayes';
requires 'Parallel::ForkManager';
requires 'POSIX::AtFork';
on 'test' => sub {
    requires 'File::Spec';
    requires 'Test::More', '0.98';
};