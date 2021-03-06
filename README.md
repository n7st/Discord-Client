# AnyEvent-Discord

Perl AnyEvent client and for Discord's WS gateway.

## Usage

* Install dependencies `dzil listdeps | cpanm`
* Example script and callback class:

```perl
#!/usr/bin/env perl

# some_script.pl

use strict;
use warnings;

use MyBot;
use Discord::Client;

my $main_class = MyBot->new();

# Initialise
my $gateway = Discord::Client->new({
    auth_token     => 'DISCORD AUTH TOKEN HERE',
    user_agent     => 'Some user agent string here',
    callback_class => $main_class,
    routines       => {
        each_message => 'message_received',
        finish       => 'finished',
        connect      => 'connected',
    },
});

# Run
$gateway->connect();
```

```perl
package MyBot;

use Moose;
use Discord::REST;

sub connected {
    my $self = shift;
    my $vars = shift; # data from Discord

    # You can respond with data to be sent back to Discord
    return {
        op => 3,
        d  => {
            idle_since => undef,
            game       => {
                name => 'Some Status',
            },
        },
    };
}

sub message_received {
    my $self = shift;
    my $vars = shift;

    my $inp = $vars->{d};

    if ($vars->{t} eq 'MESSAGE_CREATE') {
        # new message
        if ($inp->{content} eq 'ping') {
            my $rest = Discord::REST->new({
                auth_token => 'auth token from discord',
                ua_string  => 'user agent string',
            });

            # Respond 'pong' in the current channel

            $rest->call({
                content  => 'pong',
                endpoint => 'messages',
                id_0     => $vars->{d}->{channel_id},
                method   => 'POST',
                resource => 'channels',
            });
        }
    }

    return {
        # Some data to send back to Discord?
    };
}

sub finished {
    # Connection closed by Discord
}

no Moose;
1;
```

