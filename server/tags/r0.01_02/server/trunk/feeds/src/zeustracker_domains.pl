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

use CIF::Message::DomainSimple;
use CIF::Message::InfrastructureSimple;

my $timeout = 5;
my $partner = 'zeustracker.abuse.ch';
my $url = 'https://zeustracker.abuse.ch/rss.php';
my $content;
my $rss = XML::RSS->new();

$content = get($url);
$rss->parse($content);

foreach my $item (@{$rss->{items}}){
    $_ = $item->{'description'};
    my ($host,$addr,$sbl,$status,$level) = m/^Host: ($RE{'net'}{IPv4}|[A-Za-z0-9.-]+\.[A-Za-z]{2,6}), IP address: ($RE{'net'}{IPv4}|[A-Za-z0-9.-]+\.[A-Za-z]{2,6}|\s+), SBL: (\S*\s*)+, status: (\S+), level: (\d+)/;
    next unless($host && $status);
    for($level){
        $level = 'bulletproof hosted' if(/^1$/);
        $level = 'hacked webserver' if(/^2$/);
        $level = 'free hosting service' if(/^3$/);
        $level = 'unknown' if(/^4$/);
        $level = 'hosted on a fastflux botnet' if(/^5$/);
    }

    my $detecttime;
    if($item->{title} =~ /\((\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2})\)/){
        $detecttime = DateTime::Format::DateParse->parse_datetime($1);
    }
    $detecttime .= 'Z';

    my $uuid;
    if($host =~ /^$RE{net}{IPv4}$/){
        $uuid = CIF::Message::InfrastructureSimple->insert({
                source      => $partner,
                address     => $addr,
                impact      => 'zeus botnet infrastructure',
                description => 'zeus botnet infrastructure '.$level.' '.$addr,
                confidence  => 5,
                severity    => 'low',
                reporrtime  => $detecttime,
                restriction => 'need-to-know',
                alternativeid => 'https://zeustracker.abuse.ch/monitor.php?ipaddress='.$addr,
                alternativeid_restriction => 'public',
        });
    } else {  
        my $impact = 'zeus malware domain';
        $impact .= ' fastflux' if($level =~ /fastflux/);
        my $desc = $impact.' '.$level.' '.$host;
        $uuid = CIF::Message::DomainSimple->insert({
            nsres       => Net::DNS::Resolver->new(['8.8.8.8','8.8.8.4']),
            address     => $host,
            source      => $partner,
            confidence  => 5,
            severity    => 'low',
            impact      => $impact,
            description => $desc,
            detecttime  => $detecttime,
            alternativeid => 'https://zeustracker.abuse.ch/monitor.php?host='.$host,
            alternativeid_restriction => 'public',
            restriction => 'need-to-know',
        });
    }
    warn $uuid;
}
