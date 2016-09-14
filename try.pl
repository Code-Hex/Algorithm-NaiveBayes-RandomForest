use strict;
use warnings;
use FindBin;
BEGIN {
	push @INC, "$FindBin::Bin/lib";
};
use Data::Dumper;
use v5.10;

use Algorithm::NaiveBayes;

use Algorithm::NaiveBayes::RandomForest;

my $nb = Algorithm::NaiveBayes::RandomForest->new(purge => 0);
# my $nb = Algorithm::NaiveBayes::RandomForest->new->restore_state('test_save');
print Dumper $nb;

$nb->add_instance(
    attributes => {
    	Hello => 0.875,
    	World => 0.322,
    	XXX   => 0.3234
    },
    label => 'positive',
);
$nb->train;
say Dumper $nb->predict(
	attributes => {
		Hello => 1
	}
);

$nb->save_state("test_save");
