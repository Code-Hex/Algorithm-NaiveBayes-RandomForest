use strict;
use warnings;
use FindBin;
BEGIN {
	push @INC, "$FindBin::Bin/lib";
};
use Data::Dumper;
use v5.10;

use Algorithm::NaiveBayes::RandomForest;

my $nb = Algorithm::NaiveBayes::RandomForest->new(purge => 0);
# my $nb = Algorithm::NaiveBayes::RandomForest->new->restore_state('test_save');
#print Dumper $nb;

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

#$nb->save_state("test_save");
