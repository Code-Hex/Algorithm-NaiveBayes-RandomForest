package Algorithm::NaiveBayes::RandomForest;
use strict;
use warnings;
use feature ':5.10';
use vars qw/$VERSION @ISA/;

$VERSION = '0.0.1';

use Algorithm::NaiveBayes;

use Storable ();
use Parallel::ForkManager;
use POSIX::AtFork;

POSIX::AtFork->add_to_child(sub { srand });

sub new {
    my $class = shift;
    my $args = ref $_[0] eq 'HASH' ? $_[0] : {@_};

    my $verbose = delete $args->{verbose};
    my $max_processes = delete $args->{max_processes} || 2;
    my $parent = Algorithm::NaiveBayes->new(%$args);

    # In order to use the methods of the $parent class
    push @ISA, ref $parent;

    # rebless as Algorithm::NaiveBayes::RandomForest
    my $self = bless $parent, $class;

    $self->{verbose} = $verbose;
    $self->{max_processes} = $max_processes;
    $self->{model} = [];
    $self->{pm} = Parallel::ForkManager->new($max_processes);
    $self->{version} = $VERSION;
    return $self;
}

sub save_state {
    my ($self, $path) = @_;
    delete $self->{pm};
    Storable::nstore($self, $path);
}

sub restore_state {
    my ($class, $path) = @_;
    my $self = Storable::retrieve($path) or die "Can't restore state from $path: $!";
    $self->{pm} = Parallel::ForkManager->new($self->{max_processes});
    return $self;
}

sub train {
    my $self = shift;
    my $sampling = $self->_bs_sampling;

    unless (@{$self->{model}} > 0) {
        $self->{model} = [];
        for my $i (0 .. $self->{max_processes}-1) {
            push @{$self->{model}}, $self->do_train($sampling->[$i]);
        }
    }
    $self->do_purge if $self->purge;
}

sub predict {
    my ($self, %params) = @_;
    my $newattrs = $params{attributes} or die "Missing 'attributes' parameter for predict()";
    
    my $result = {};

    for my $model (@{ $self->{model} }) {
        my $predict = $self->do_predict($model, $newattrs);
        $result->{$_} += $predict->{$_} for keys %$predict;
    }

    my $model_count = @{ $self->{model} };

    return { map { $_ => ($result->{$_} / $model_count) + 0.0 } keys %$result};
}

# bootstrap sampling
sub _bs_sampling {
    my $self = shift;

    my $dataset = $self->{training_data}{attributes};

    my $keys = [ keys %$dataset ];
    my $T = $#$keys;
    my $trees = $self->{max_processes};
    my $sampling = [];

    $self->{pm}->run_on_finish(
        sub {
            my $data = pop;
            push @$sampling, $data if defined $data;
        }
    );

    foreach my $t (1..$trees) {
        $self->{pm}->start and next;
        my $dict = +{};
        my @randkeys = map { $keys->[int rand($T + 1)] } 0 .. $T + 1;
        # make dataset
        $dict->{attributes}{$_} = $dataset->{$_} for @randkeys;
        $dict->{labels} = $self->{training_data}{labels};

        $self->{pm}->finish(0, $dict);
    }
    $self->{pm}->wait_all_children;

    return $sampling;
}

1;
__END__

=encoding utf-8

=head1 NAME

Algorithm::NaiveBayes::RandomForest - RandomForest using Algorithm::NaiveBayes

=head1 SYNOPSIS

    use Algorithm::NaiveBayes::RandomForest;

    # 'max_processes' assignment child processes.
    # This number is used as the number of trees.
    my $nb = Algorithm::NaiveBayes::RandomForest->new(purge => 0, max_processes => 4);
    
    # If you have 'save_file', you can use this method
    # my $nb = Algorithm::NaiveBayes::RandomForest->new->restore_state('save_file'); 

    $nb->add_instance(
        attributes => {
            Like => 0.875,
            Nice => 0.322,
            Thanks   => 0.3234
        },
        label => 'positive',
    );
    $nb->add_instance(
        attributes => {
            Unlike => 0.583,
            Bad => 0.294
        },
        label => 'negative',
    );

    $nb->train;

    use Data::Dumper;
    say Dumper $nb->predict(
        attributes => {
            Unlike => 0.332,
            Like   => 0.553,
            Nice   => 0.872
        }
    );

=head1 DESCRIPTION

Algorithm::NaiveBayes::RandomForest is inheritance by L<Algorithm::NaiveBayes>.  
So, you can use same method as Algorithm::NaiveBayes.

=head1 SEE ALSO

L<Algorithm::NaiveBayes>

=head1 LICENSE

Copyright (C) Kei Kamikawa(Code-Hex).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kei Kamikawa E<lt>x00.x7f@gmail.comE<gt>

=cut

