use strict;
use Test::More 0.98;
use File::Spec;
BEGIN {
	push @INC, "$FindBin::Bin/lib";
};
use Algorithm::NaiveBayes::RandomForest;
my $nb = Algorithm::NaiveBayes::RandomForest->new(purge => 0);
ok $nb;

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

ok $nb->purge == 0;

# labels
for my $label (qw/positive negative/) {
	ok(ref $nb->training_data->{labels}{$label} eq 'HASH', "training_data has labels: '$label'");
}

# attributes
for my $key (qw/Like Nice Thanks Unlike Bad/) {
	ok($nb->training_data->{attributes}{$key} > 0, "training_data has attributes: '$key'");
}

# Save
my $file = File::Spec->catfile('t', 'model.dat');
$nb->save_state($file);
ok -e $file;

# Restore
$nb = Algorithm::NaiveBayes::RandomForest->restore_state($file);
ok $nb;
ok $nb->can('predict');

done_testing;