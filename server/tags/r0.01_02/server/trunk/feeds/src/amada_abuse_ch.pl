#!/usr/bin/perl -w

use strict;
use XML::RSS;
use LWP::Simple;
use Data::Dumper;
use Net::Abuse::Utils qw(:all);
use Regexp::Common qw/net/;
use DateTime::Format::DateParse;
use DateTime;
use Net::DNS;

use CIF::Message::UrlMalware;
use CIF::Message::DomainSimple;

my $timeout = 5;
my $partner = 'amada.abuse.ch';
my $url = 'http://amada.abuse.ch/recent.php';
my $content;
my $rss = XML::RSS->new();

$content = get($url);
$rss->parse($content);

die Dumper($rss);

foreach my $item (@{$rss->{items}}){
    my ($url,$addr,$asn,$country,$desc) = split(/,/,$item->{description});
    $url =~ s/Host: //;
    $addr =~ s/ IP address: //;
    $desc =~ s/ Description: //; 
    if($url =~ /^\-/){
        $url = $addr;
        $addr =~ /^($RE{net}{IPv4})/;
        $addr = $1;
    }

    my $detecttime;
    if($item->{title} =~ /\((\d{4}\/\d{2}\/\d{2}_\d{2}:\d{2})\)/){
        my $t = $1;
        $t =~ s/_/ /;
        $detecttime = DateTime::Format::DateParse->parse_datetime($t);
    }
    $detecttime .= 'Z';

    my $domain = $item->{'title'};
    if($domain =~ /^($RE{net}{IPv4})/){
        $domain = $1;
    } else {
        $domain =~ /^([A-Za-z0-9.-]+\.[a-zA-Z]{2,6})/;
        $domain = $1;
    }

    my $impact = 'malware url';
    my $uuid = CIF::Message::UrlMalware->insert({
        address     => $url,
        source      => $partner,
        impact      => $impact,
        description => $impact.' '.$desc,
        confidence  => 3,
        severity    => 'medium',
        restriction => 'need-to-know',
        alternativeid  => 'http://www.malwaredomainlist.com/mdl.php?quantity=50&inactive=on&search='.$domain,
        alternativeid_restriction => 'public',
        detecttime  => $detecttime,
    });

    $impact = 'malware domain '.$desc;
    $desc = $impact.' '.$desc;
    my $duuid = CIF::Message::DomainSimple->insert({
        nsres       => Net::DNS::Resolver->new(['8.8.8.8','8.8.8.4']),
        address     => $domain,
        source      => $partner,
        confidence  => 5,
        severity    => 'medium',
        impact      => $impact,
        description => $desc,
        relatedid   => $uuid->uuid(),
        detecttime  => $detecttime,
        alternativeid => 'http://www.malwaredomainlist.com/mdl.php?quantity=50&inactive=on&search='.$domain,
        alternativeid_restriction => 'public',
        restriction => 'need-to-know',
    });
    if($addr =~ /^$RE{'net'}{'IPv4'}/){
        my $ipid = CIF::Message::InfrastructureSimple->insert({
            address => $addr,
            source  => $partner,
            confidence  => 5,
            severity    => 'low',
            impact      => 'suspicious address',
            description => 'suspicious address malware url',
            relatedid   => $uuid->uuid(),
            detecttime  => $detecttime,
            alternativeid => 'http://www.malwaredomainlist.com/mdl.php?quantity=50&inactive=on&search='.$addr,
            alternativeid_restriction => 'public',
            restriction => 'need-to-know',
        });
    }
    print $uuid.' -- '.$uuid->uuid().' -- '.$url."\n";
}
