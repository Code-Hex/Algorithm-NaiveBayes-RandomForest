use strict;
use Test::More 0.98;

BEGIN {
	push @INC, "$FindBin::Bin/lib";
};
use Algorithm::NaiveBayes::RandomForest;
my $nb = Algorithm::NaiveBayes::RandomForest->new(purge => 0);

$nb->add_instance(
    attributes => {
        Like   => 0.875,
        Nice   => 0.322,
        Thanks => 0.3234
    },
    label => 'positive',
);

$nb->add_instance(
    attributes => {
        Unlike => 0.583,
        Bad    => 0.294
    },
    label => 'negative',
);

$nb->train;

for my $label (qw/positive negative/) {
	ok(ref $nb->training_data->{labels} eq 'HASH', "training_data has labels: '$label'");
}

for my $key (qw/Like Nice Thanks Unlike Bad/) {
	ok($nb->training_data->{attributes}{$key} > 0, "training_data has attributes: '$key'");
}

done_testing;