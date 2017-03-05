package Discord::Gateway;

use AnyEvent;
use AnyEvent::WebSocket::Client;
use Carp qw/carp cluck confess/;
use Data::Printer;
use JSON::XS;
use Moose;
use Try::Tiny;
use URI;

use Discord::REST;

################################################################################

has auth_token     => (is => 'ro', isa => 'Str',     required => 1);
has callback_class => (is => 'ro', isa => 'Object',  required => 1);
has routines       => (is => 'ro', isa => 'HashRef', required => 1);
has user_agent     => (is => 'ro', isa => 'Str',     required => 1);

has api            => (is => 'ro', isa => 'Discord::REST', lazy_build => 1);
has heartbeat_loop => (is => 'rw', isa => 'EV::Timer',     lazy_build => 1);
has wss            => (is => 'ro', isa => 'URI::wss',      lazy_build => 1);

has connection         => (is => 'rw', isa => 'Maybe[AnyEvent::WebSocket::Connection]');
has heartbeat_interval => (is => 'rw', isa => 'Num');
has session_id         => (is => 'rw', isa => 'Str');

has large_threshold        => (is => 'rw', isa => 'Int',     default => 250);
has sent_initial_heartbeat => (is => 'rw', isa => 'Int',     default => 0);
has sequence_id            => (is => 'rw', isa => 'Int',     default => 0);
has connection_operation   => (is => 'rw', isa => 'HashRef', default => sub { {} });

################################################################################

sub connect {
    my $self = shift;

    my $cv     = AnyEvent->condvar;
    my $client = AnyEvent::WebSocket::Client->new();
    my $uri    = URI->new($self->wss);

    $client->connect($self->wss)->cb(sub {
        my $connection = eval { shift->recv };
        die $@ if $@;

        $self->connection($connection);

        $self->connection->on(each_message => sub {
            my $conn = shift;
            my $resp = shift;

            my $content = decode_json($resp->body);
            my $response;

            $self->sequence_id($content->{s}) if $content->{s};

            $self->hello($content)       if $content->{op} == 10;
            $self->resume($content)      if $content->{op} == 7;

            if ($content->{op} == 0 && $content->{t} eq 'READY') {
                $self->_initialise($content);
                $self->connection_operation($self->_run_external_subroutine('connect', $content))
                    if $self->routines->{connect};
            }

            try {
                $response = $self->_run_external_subroutine('each_message', $content);
            } catch {
                cluck $_;
            };

            if ($response && $response->{op} && $response->{d}) {
                $self->send_op($response->{op} => { d => $response->{d} });
            }
        });

        $self->connection->on(finish => sub {
            try {
                $self->_run_external_subroutine('finish', @_);
                $self->connect();
            } catch {
                cluck $_;
            };
        });
    });

    return $cv->recv;
}

sub hello {
    my $self      = shift;
    my $vars      = shift;
    my $is_resume = shift;

    my $interval = $vars->{d}->{heartbeat_interval};

    if ($interval) {
        $interval = $interval / 1000;

        $self->heartbeat_interval($interval);
        $self->heartbeat_loop->start();
    }

    my $data = {
        compress        => 1,
        large_threshold => $self->large_threshold,
        token           => $self->auth_token,
        properties      => {
            '$os'               => $^O,
            '$browser'          => 'Discord::Gateway ("", 0.0.1)',
            '$device'           => 'Discord::Gateway 0.0.1',
            '$referrer'         => '',
            '$referring_domain' => '',
        },
    };

    if ($is_resume) {
        $data->{seq}        = $self->sequence_id;
        $data->{session_id} = $self->session_id;
    }

    carp "Saying hello to the server";

    return $self->send_op(2 => { d => $data });
}

sub resume {
    my $self = shift;
    my $vars = shift;

    cluck "Resuming last connection";

    return $self->hello($vars, reconnect => 1);
}

sub heartbeat {
    my $self = shift;
    my $vars = shift;

    $self->sent_initial_heartbeat(1) unless $self->sent_initial_heartbeat;

    carp "Sending a heartbeat";

    return $self->send_op(1 => {
        d => $self->sequence_id,
    });
}

sub send_op {
    my $self = shift;
    my $id   = shift;
    my $vars = shift;

    carp sprintf("Sending operation %d", $id);

    return $self->connection->send(encode_json({
        op => $id,
        %{$vars},
    }));
}

################################################################################

sub _initialise {
    my $self = shift;
    my $vars = shift;

    $self->heartbeat($vars);
    $self->session_id($vars->{d}->{session_id});

    if ($self->connection_operation && $self->connection_operation->{d}) {
        $self->send_op($self->connection_operation->{op} => {
            d => $self->connection_operation->{d},
        });
    }

    return 1;
}

sub _run_external_subroutine {
    my $self = shift;
    my $key  = shift;

    my $class   = $self->callback_class;
    my $routine = $self->routines->{$key};

    carp sprintf("Running %s::%s", ref $class, $routine);

    return $class->$routine(@_);
}

################################################################################

sub _build_api {
    my $self = shift;

    return Discord::REST->new({
        auth_token => $self->auth_token,
        ua_string  => $self->user_agent,
    });
}

sub _build_heartbeat_loop {
    my $self = shift;

    my $loop = AnyEvent->timer(
        after    => $self->heartbeat_interval,
        interval => $self->heartbeat_interval,
        cb       => sub {
            $self->heartbeat();
        },
    );

    $loop->stop() unless $self->sent_initial_heartbeat;

    return $loop;
}

sub _build_wss {
    my $self = shift;

    my $wss = $self->api->call({
        method   => 'get',
        resource => 'gateway',
    });

    my $uri = URI->new(sprintf("%s/bot?v=5&encoding=json", $wss->{url}));

    return $uri;
}

################################################################################

no Moose;
1;
__END__

