package Discord::REST::Channel;

use Moose;

use Discord::REST::Channel::Message;

extends 'Discord::REST';

################################################################################

has default_args => (is => 'ro', isa => 'HashRef',                         lazy_build => 1);
has message      => (is => 'ro', isa => 'Discord::REST::Channel::Message', lazy_build => 1);

################################################################################

around qw/get modify delete/ => sub {
    my $orig = shift;
    my $self = shift;

    unless ($_[0]->{channel_id}) {
        return { error => 'Parameter `channel_id` is required' };
    }

    return $self->$orig(@_);
};

################################################################################

sub get {
    my $self = shift;
    my $args = shift;

    return $self->_call({
        method => 'GET',
        id_0   => $args->{channel_id},

        %{$self->default_args},
    });
}

sub modify {
    my $self = shift;
    my $args = shift;

    return $self->_call({
        method  => 'PATCH',
        id_0    => $args->{channel_id},
        content => $args->{content},

        %{$self->default_args},
    });
}

sub delete {
    my $self = shift;
    my $args = shift;

    return $self->_call({
        method => 'DELETE',
        id_0   => $args->{channel_id},

        %{$self->default_args},
    });
}

################################################################################

sub _build_default_args {
    return {
        resource => 'channels',
    };
}

sub _build_message { shift->_build_resource('Channel::Message'); }

################################################################################

no Moose;
1;
__END__

