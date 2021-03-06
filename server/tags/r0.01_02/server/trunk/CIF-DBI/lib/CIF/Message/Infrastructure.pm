package CIF::Message::Infrastructure;
use base 'CIF::DBI';

use strict;
use warnings;

use XML::IODEF;
use CIF::Message::IODEF;
use Net::CIDR;
use Net::Abuse::Utils qw(:all);
use Regexp::Common qw/net/;

__PACKAGE__->table('infrastructure');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw/id uuid description impact address cidr asn asn_desc cc rir protocol portlist confidence source severity restriction alternativeid alternativeid_restriction detecttime created/);
__PACKAGE__->columns(Essential => qw/id uuid description address restriction created/);
__PACKAGE__->sequence('infrastructure_id_seq');

my @list = (
    "0.0.0.0/8",
    "10.0.0.0/8",
    "127.0.0.0/8",
    "192.168.0.0/16",
    "169.254.0.0/16",
    "192.0.2.0/24",
    "224.0.0.0/4",
    "240.0.0.0/5",
    "248.0.0.0/5"
);

sub isPrivateAddress {
    my $addr = shift;
    return(undef) unless($addr);
    my $found = Net::CIDR::cidrlookup($addr,@list);
    return($found);
}

sub asninfo {
    my $a = shift;
    return undef unless($a);
    my ($as,$network,$ccode,$rir,$date) = get_asn_info($a);
    my $as_desc;
    $as_desc = get_as_description($as) if($as);

    $as         = undef if($as && $as eq 'NA');
    $network    = undef if($network && $network eq 'NA');
    $ccode      = undef if($ccode && $ccode eq 'NA');
    $rir        = undef if($rir && $rir eq 'NA');
    $date       = undef if($date && $date eq 'NA');
    $as_desc    = undef if($as_desc && $as_desc eq 'NA');
    $a          = undef if($a eq '');
    return ($as,$network,$ccode,$rir,$date,$as_desc);
}

my $tests = {
    'severity'      => qr/^(low|medium|high||)$/,
    'address'       => qr/^$RE{'net'}{'IPv4'}/,
    'confidence'    => qr/\d+/,
};

sub insert {
    my $self = shift;
    my $info = {%{+shift}};

    my ($ret,$err) = $self->check_params($tests,$info);
    return($ret,$err) unless($ret);

    my $proto = convertProto($info->{'protocol'});
    my $uuid = $info->{'uuid'};
    my $source = $info->{'source'};
    
    $source = CIF::Message::genSourceUUID($source) unless(CIF::Message::isUUID($source));
    $info->{'source'} = $source;
    $info->{'protocol'} = $proto;

    unless($uuid){
        $uuid = CIF::Message::IODEF->insert({
            message => $self->toIODEF($info)
        });
        $uuid = $uuid->uuid();
    }

    my $id = eval { $self->SUPER::insert({
        uuid        => $uuid,
        description => $info->{'description'},
        impact      => $info->{'impact'},
        address     => $info->{'address'},
        cidr        => $info->{'cidr'},
        asn         => $info->{'asn'},
        asn_desc    => $info->{'asn_desc'},
        cc          => $info->{'cc'},
        rir         => $info->{'rir'},
        protocol    => $info->{'protocol'},
        portlist    => $info->{'portlist'},
        confidence  => $info->{'confidence'},
        source      => $info->{'source'},
        severity    => $info->{'severity'},
        restriction => $info->{'restriction'} || 'private',
        detecttime  => $info->{'detecttime'},
        impact      => $info->{'impact'},
        alternativeid   => $info->{'alternativeid'},
        alternativeid_restriction => $info->{'alternativeid_restriction'} || 'private',
    }) };
    if($@){
        return(undef,$@) unless($@ =~ /duplicate key value violates unique constraint/);
        $id = $self->retrieve(uuid => $uuid);
    }
    return($id);
}

sub convertProto {
    my $proto = shift;
    return unless($proto);
    return($proto) if($proto =~ /^\d+$/);

    for(lc($proto)){
        if(/^tcp$/){ $proto = 6; }
        if(/^udp$/){ $proto = 17; }
        if(/^icmp$/){ $proto = 1; }
    }
    $proto = undef unless($proto =~ /^\d+$/);
    return($proto);
}

sub toIODEF {
    my $self = shift;
    my $info = {%{+shift}};

    my $impact      = $info->{'impact'};
    my $address     = $info->{'address'};
    my $description = $info->{'description'};
    my $cidr        = $info->{'cidr'};
    my $asn         = $info->{'asn'};
    my $asn_desc    = $info->{'asn_desc'};
    my $cc          = $info->{'cc'},
    my $rir         = $info->{'rir'},
    my $protocol    = $info->{'protocol'};
    my $portlist    = $info->{'portlist'};
    my $confidence  = $info->{'confidence'};
    my $severity    = $info->{'severity'};
    my $restriction = $info->{'restriction'} || 'private';
    my $source      = $info->{'source'};
    my $detecttime  = $info->{'detecttime'};
    my $relatedid   = $info->{'relatedid'};
    my $alternativeid  = $info->{'alternativeid'};
    my $alternativeid_restriction = $info->{'alternativeid_restriction'} || 'private';

    die('source or source uuid required') unless($source);

    my $iodef = XML::IODEF->new();
    $iodef->add('Incidentrestriction',$restriction);
    $iodef->add('IncidentDescription',$description);
    $iodef->add('IncidentIncidentIDname',$source);
    if($relatedid){
        $iodef->add('IncidentRelatedActivityIncidentID',$relatedid);
    }
    if($alternativeid){
        $iodef->add('IncidentAlternativeIDIncidentID',$alternativeid);
        $iodef->add('IncidentAlternativeIDIncidentIDrestriction',$alternativeid_restriction);
    }

    $iodef->add('IncidentDetectTime',$detecttime) if($detecttime);
    $iodef->add('IncidentAssessmentImpact',$impact);
    if($confidence){
        $iodef->add('IncidentAssessmentConfidencerating','numeric');
        $iodef->add('IncidentAssessmentConfidence',$confidence);
    }
    $iodef->add('IncidentAssessmentImpactseverity',$severity) if($severity);
    $iodef->add('IncidentEventDataFlowSystemNodeAddresscategory','ipv4-addr'); ## TODO -- regext this
    $iodef->add('IncidentEventDataFlowSystemNodeAddress',$address);
    $iodef->add('IncidentEventDataFlowSystemServicePortlist',$portlist) if($portlist);
    $iodef->add('IncidentEventDataFlowSystemServiceip_protocol',$protocol) if($protocol);
    if($asn){
        $asn .= ' '.$asn_desc if($asn_desc);
        $iodef->add('IncidentEventDataFlowSystemNodeAddresscategory','asn');
        $iodef->add('IncidentEventDataFlowSystemNodeAddress',$asn);
    }
    if($cidr){
        $iodef->add('IncidentEventDataFlowSystemNodeAddresscategory','ipv4-net');
        $iodef->add('IncidentEventDataFlowSystemNodeAddress',$cidr);
    }
    if($cc){
        $iodef->add('IncidentEventDataFlowSystemNodeLocation',$cc);
    }
    if($rir){
        $iodef->add('IncidentEventDataFlowSystemAdditionalDatadtype','string');
        $iodef->add('IncidentEventDataFlowSystemAdditionalDatameaning','RIR');
        $iodef->add('IncidentEventDataFlowSystemAdditionalData',$rir);
    }
    return $iodef->out();
}

sub lookup {
    my ($self,$address,$apikey,$limit,$silent) = @_;
    $limit = 5000 unless($limit);
    #my $source = CIF::Message::genSourceUUID('api',$apikey);
    my $asn;
    my $description = 'search '.$address;
    if($address !~ /^$RE{net}{IPv4}/){
        $asn = $address;
        $asn =~ s/^(AS|as)//;
        $address = '0/0';
    }
    my $dt = DateTime->from_epoch(epoch => time());
    $dt = $dt->ymd().'T'.$dt->hour().':00:00Z';

    my @recs;
    if($asn){
        @recs = $self->search_by_asn($asn,$limit);
    } else {
        @recs = $self->search_by_address($address,$address,$limit);
    }

    return @recs if($silent);

    my $t = $self->table();
    $self->table('infrastructure_search');
    my $sid = $self->insert({
        address => $address,
        asn     => $asn,
        impact  => 'search',
        source  => 'api'.$apikey,
        description => $description,
        detecttime  => $dt,
    });
    $self->table($t);
    return @recs;
}

sub isWhitelisted {
    my $self = shift;
    my $a = shift;

    return undef unless($a);

    my $sql = qq{
        family(address) = 4 AND masklen(address) < 32 AND '$a' <<= address 
        ORDER BY detecttime DESC, created DESC, id DESC
    };

    my $t = $self->table();
    $self->table('infrastructure_whitelist');
    my @ret = $self->retrieve_from_sql($sql);
    $self->table($t);
    return @ret;
}

__PACKAGE__->set_sql('by_address' => qq{
    SELECT * FROM __TABLE__
    WHERE address != '0/0'
    AND (address >>= ? OR address <<= ?)
    ORDER BY detecttime DESC, created DESC, id DESC
    LIMIT ?
});

__PACKAGE__->set_sql('by_asn' => qq{
    SELECT * FROM __TABLE__
    WHERE asn = ?
    ORDER BY detecttime DESC, created DESC, id DESC
    LIMIT ?
});

1;

__END__
