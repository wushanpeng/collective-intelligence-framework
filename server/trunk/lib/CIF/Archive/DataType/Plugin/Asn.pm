package CIF::Archive::DataType::Plugin::Asn;
use base 'CIF::Archive::DataType';

use strict;
use warnings;

use Module::Pluggable require => 1, search_path => [__PACKAGE__], except => qr/SUPER$/;
use DateTime;

__PACKAGE__->table('asn');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw/id uuid asn asn_desc source guid confidence severity restriction detecttime created/);
__PACKAGE__->columns(Essential => qw/id uuid asn asn_desc source guid confidence severity restriction detecttime created/);
__PACKAGE__->sequence('asn_id_seq');

my @plugins = __PACKAGE__->plugins();

# Preloaded methods go here.

sub prepare {
    my $class = shift;
    my $info = shift;

    ## TODO -- download list of IANA country codes for use in regex
    ## http://data.iana.org/TLD/tlds-alpha-by-domain.txt
    if($info->{'address'} && $info->{'address'} =~ /^as([0-9]*\.?[0-9]*)$/){
        $info->{'asn'} = $1;
    }
    return unless($info->{'asn'});
    return unless($info->{'asn'} =~ /^[0-9]*\.?[0-9]*$/);

    return(1);
}

sub insert {
    my $class = shift;
    my $info = shift;

    my $table = $class->table();
    foreach(@plugins){
        if($_->prepare($info)){
            $class->table($_->table());
        }
    }

    my $id = eval { $class->SUPER::insert({
        uuid        => $info->{'uuid'},
        asn         => $info->{'asn'},
        asn_desc    => $info->{'asn_desc'},
        source      => $info->{'source'},
        confidence  => $info->{'confidence'},
        severity    => $info->{'severity'} || 'null',
        restriction => $info->{'restriction'} || 'private',
        detecttime  => $info->{'detecttime'},
        guid        => $info->{'guid'},
        created     => $info->{'created'} || DateTime->from_epoch(epoch => time()),
    }) };
    if($@){
        return(undef,$@) unless($@ =~ /duplicate key value violates unique constraint/);
    }
    $class->table($table);
}

sub lookup {
    my $class = shift;
    my $info = shift;
    my $q = $info->{'query'};
    return unless($q =~ /^AS([0-9]*\.?[0-9]*)$/);
    $q = $1;

    if($info->{'guid'}){
        return(
            $class->search__lookup(
                $q,
                $info->{'severity'},
                $info->{'confidence'},
                $info->{'restriction'},
                $info->{'guid'},
                $info->{'limit'}
            )
        );
    }
    return(
        $class->search_lookup(
            $q,
            $info->{'severity'},
            $info->{'confidence'},
            $info->{'restriction'},
            $info->{'apikey'},
            $info->{'limit'}
        )
    );
}

sub feed {
    my $class = shift;
    my $info = shift;

    my @feeds;

    # this doesn't work quite yet.
    # gets stuck on recursive loop because of count()
    ## TODO -- finish
    #return(\@feeds);
    $info->{'key'} = 'asn';
    my $ret = $class->_feed($info);
    return unless($ret);
    push(@feeds,$ret) if($ret);

    foreach(@plugins){
        my $r = $_->_feed($info);
        push(@feeds,$r) if($r);
    }
    return(\@feeds);
}

sub isWhitelisted {}

__PACKAGE__->set_sql('feed' => qq{
    SELECT count(asn),asn
    FROM __TABLE__
    LEFT JOIN apikeys_groups ON __TABLE__.guid = apikeys_groups.guid
    LEFT JOIN archive ON __TABLE__.uuid = archive.uuid
    WHERE
        detecttime >= ?
        AND __TABLE__.confidence >= ?
        AND severity >= ?
        AND __TABLE__.restriction <= ?
        AND apikeys_groups.uuid = ?
    GROUP BY asn
    ORDER BY count DESC
    LIMIT ?
});

__PACKAGE__->set_sql('_lookup' => qq{
    SELECT __TABLE__.id,__TABLE__.uuid, archive.data 
    FROM __TABLE__
    LEFT JOIN archive ON archive.uuid = __TABLE__.uuid
    WHERE 
        asn = ?
        AND severity >= ?
        AND confidence >= ?
        AND __TABLE__.restriction <= ?
        AND __TABLE__.guid = ?
    ORDER BY __TABLE__.detecttime DESC, __TABLE__.created DESC, __TABLE__.id DESC
    LIMIT ?
});

__PACKAGE__->set_sql('lookup' => qq{
    SELECT __TABLE__.id,__TABLE__.uuid,archive.data
    FROM __TABLE__
    LEFT JOIN apikeys_groups on __TABLE__.guid = apikeys_groups.guid
    LEFT JOIN archive ON archive.uuid = __TABLE__.uuid
    WHERE 
        asn = ?
        AND severity >= ?
        AND confidence >= ?
        AND __TABLE__.restriction <= ?
        AND apikeys_groups.uuid = ?
    ORDER BY __TABLE__.detecttime DESC, __TABLE__.created DESC, __TABLE__.id DESC
    LIMIT ?
});

1;
__END__
=head1 NAME

 CIF::Archive::DataType::Plugin::ASN - Perl extension for indexing ASN's

=head1 SEE ALSO

 http://code.google.com/p/collective-intelligence-framework/
 CIF::Archive

=head1 AUTHOR

 Wes Young, E<lt>wes@barely3am.comE<gt>

=head1 COPYRIGHT AND LICENSE

 Copyright (C) 2011 by Wes Young (claimid.com/wesyoung)
 Copyright (C) 2011 by the Trustee's of Indiana University (www.iu.edu)
 Copyright (C) 2011 by the REN-ISAC (www.ren-isac.net)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
