#!/usr/bin/perl -w

use CIF::Message::DomainWhitelist;
use DateTime;
use Config::Simple;

my $date = DateTime->from_epoch(epoch => time());
$date = $date->ymd().'T00:00:00Z';

# your own personal whitelist;
my $cfg = Config::Simple->new($ENV{'HOME'}.'/.cif') || die($!);
my $feed = $cfg->param(-block => 'feed_sources')->{'domains_whitelist'} || die('missing feed: '.$!);

open(F,$feed) || die($!);

while(<F>){
    my $line = $_;
    $line =~ s/\n//;
    my $id = CIF::Message::DomainWhitelist->insert({
        source      => 'localhost',
        impact      => 'domain whitelist',
        description => 'domain whitelist '.$line,
        address     => $line,
        confidence  => 10,
        detecttime  => $date,
        restriction => 'need-to-know',
    });
    warn $id;
}
close(F);
