package Discord::REST::Gateway;

use Moose;

extends 'Discord::REST';

################################################################################

has default_args => (is => 'ro', isa => 'HashRef', lazy_build => 1);

################################################################################

sub url {
    my $self = shift;

    return $self->_call({
        method => 'GET',
        %{$self->default_args},
    });
}

################################################################################

sub _build_default_args {
    return {
        resource => 'gateway',
    };
}

################################################################################

no Moose;
1;
__END__

