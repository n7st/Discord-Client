package Discord::Roles::Gateways;

use Moose::Role;

################################################################################

has gateways       => (is => 'ro', isa => 'HashRef', lazy_build => 1);
has gateway_errors => (is => 'ro', isa => 'HashRef', lazy_build => 1);

################################################################################

sub _build_gateways {
    return {
        0  => 'Dispatch',
        1  => 'Heartbeat',
        2  => 'Identify',
        3  => 'Status Update',
        4  => 'Voice Status Update',
        5  => 'Voice Server Ping',
        6  => 'Resume',
        7  => 'Reconnect',
        8  => 'Request Guild Members',
        9  => 'Invalid Session',
        10 => 'Hello',
        11 => 'Heartbeat ACK',
    };
}

sub _build_gateway_errors {
    4000 => {
        desc  => 'unknown error',
        error => "We're not sure what went wrong. Try reconnecting?",
    },
    4001 => {
        desc  => 'unknown opcode',
        error => "You sent an invalid Gateway OP Code. Don't do that!",
    },
    4002 => {
        desc  => 'decode error',
        error => "You sent an invalid payload to us. Don't do that!",
    },
    4003 => {
        desc  => 'not authenticated',
        error => "You sent us a payload prior to identifying.",
    },
    4004 => {
        desc  => 'authentication failed',
        error => "The account token sent with your identify payload is incorrect.",
    },
    4005 => {
        desc  => 'already authenticated',
        error => "You sent more than one identify payload. Don't do that!",
    },
    4007 => {
        desc  => 'invalid seq',
        error => "The sequence sent when resuming the session was invalid. Reconnect and start a new session.",
    },
    4008 => {
        desc  => 'rate limited',
        error => "Woah nelly! You're sending payloads to us too quickly. Slow it down!",
    },
    4009 => {
        desc  => 'session timeout',
        error => "Your session timed out. Reconnect and start a new one.",
    },
    4010 => {
        desc  => 'invalid shard',
        error => "You sent us an invalid shard when identifying.",
    },
}

################################################################################

no Moose;
1;

