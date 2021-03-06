package CIF::Archive::DataType::Plugin::Infrastructure::Suspicious;
use base 'CIF::Archive::DataType::Plugin::Infrastructure';

__PACKAGE__->table('infrastructure_suspicious');

sub prepare {
    my $class = shift;
    my $info = shift;

    return unless($info->{'impact'} =~ /suspicious/);
    # guard against collisions with the Network plugin
    return if($info->{'impact'} =~ /network/);
    return('suspicious');
}
1;
