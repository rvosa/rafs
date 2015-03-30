#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';
use Getopt::Long;
use Bio::Taxon;

my ( $rootid, $level, @member, $db );
GetOptions(
	'rootid=i' => \$rootid,
	'level=s'  => \$level,
	'member=s' => \@member,
	'db=s'     => \$db,
);

my $dbh = Bio::DB::Taxonomy->new( 
	'-source'    => 'flatfile',
	'-nodesfile' => "${db}/nodes.dmp",
	'-namesfile' => "${db}/names.dmp",
	'-directory' => $db,
);
my $root = $dbh->get_taxon( '-taxonid' => $rootid );
my %seen;
recurse($root);

say join "\t", $level, @member;
for my $outer ( keys %seen ) {
	my @record = ( $outer );
	push @record, $seen{$outer}->{$_} for @member;
	say join "\t", @record; 
}

sub recurse {
	my ( $node, $ancestor ) = @_;
	my $rank = $node->rank;
	if ( $rank eq $level ) {
		$ancestor = $node->scientific_name;
		$seen{$ancestor} = {};
		warn "$level: $ancestor\n";
	}
	if ( grep { /^$rank$/ } @member ) {
		$seen{$ancestor}->{$rank}++;
		my $name = $node->scientific_name;
		warn "$rank: $name\n";
	}
	for my $child ( $node->db_handle->each_Descendent($node) ) {
		recurse( $child, $ancestor );
	}
}