package Discord::REST::Channel::Message;

use Moose;

extends 'Discord::REST::Channel';

################################################################################

around qw/list send react/ => sub {
    my $orig = shift;
    my $self = shift;

    my @errors;

    unless ($_[0]->{channel_id}) {
        push @errors, { error => 'Parameter `channel_id` is required.' };
    }

    return @errors if @errors;
    return $self->$orig(@_);
};

################################################################################

sub list {
    my $self = shift;
    my $args = shift;

    my $query_str = $self->_query_string([ "around", "before", "after", "limit" ], $args);

    return $self->_call({
        method   => 'GET',
        id_0     => $args->{channel_id},
        id_1     => $args->{message_id},
        endpoint => 'messages',
        query    => $query_str,

        %{$self->default_args},
    });
}

sub send {
    my $self = shift;
    my $args = shift;

    return $self->_call({
        id_0         => $args->{channel_id},
        method       => 'POST',
        endpoint     => 'messages',
        content_type => 'multipart/form-data',
        content_str  => $args->{content},
        nonce        => $args->{nonce},
        tts          => $args->{tts} ? 1 : 0,
        file         => $args->{file},
        embed        => $args->{embed},

        %{$self->default_args},
    }); 
}

sub react {

}

################################################################################

no Moose;
1;
__END__

