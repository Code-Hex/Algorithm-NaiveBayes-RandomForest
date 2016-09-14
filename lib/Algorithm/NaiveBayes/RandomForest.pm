package Algorithm::NaiveBayes::RandomForest;
use strict;
use warnings;
use feature ':5.10';
use vars qw/$VERSION @ISA/;

$VERSION = '0.0.1';

use Algorithm::NaiveBayes;

use Storable ();
use Data::Dumper;
use Parallel::ForkManager;
use POSIX::AtFork;

POSIX::AtFork->add_to_child(sub { srand });

use constant DEBUG => 1;

use Data::Dumper;


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
    $self;
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

# train(HASH)
# HASH = {label => "~", trees => N, data => data}
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
        my $randkeys = [ map { $keys->[int rand($T + 1)] } 0 .. $T + 1 ];
         # make dataset
        $dict->{$_} = $dataset->{$_} for @$randkeys;
        $dict->{labels} = $self->{training_data}{labels};

        $self->{pm}->finish(0, $dict);
    }
    $self->{pm}->wait_all_children;

    return $sampling;
}

# __PACKAGE__->meta->make_immutable();

1;
__END__

=encoding utf-8

=head1 NAME

Algorithm::NaiveBayes::RandomForest - It's new $module

=head1 SYNOPSIS

    use Algorithm::NaiveBayes::RandomForest;

=head1 DESCRIPTION

Algorithm::NaiveBayes::RandomForest is ...

=head1 LICENSE

Copyright (C) K.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

K E<lt>x00.x7f@gmail.comE<gt>

=cut

