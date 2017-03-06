package Discord::REST;

use Data::Printer;
use HTTP::Headers;
use HTTP::Request;
use JSON::XS;
use LWP::UserAgent;
use Moose;

use Discord::REST::Gateway;
use Discord::REST::Channel;

################################################################################

has auth_token => (is => 'ro', isa => 'Str', required => 1);
has ua_string  => (is => 'ro', isa => 'Str', required => 1);

has base_url => (is => 'ro', isa => 'Str', default => 'https://discordapp.com/api');

has http_headers => (is => 'ro', isa => 'HTTP::Headers',  lazy_build => 1);
has user_agent   => (is => 'ro', isa => 'LWP::UserAgent', lazy_build => 1);

has gateway => (is => 'ro', isa => 'Discord::REST::Gateway', lazy_build => 1);
has channel => (is => 'ro', isa => 'Discord::REST::Channel', lazy_build => 1);

################################################################################

sub call {
    my $self = shift;
    my $args = shift;

    my $content  = $args->{content} ? encode_json({ content => $args->{content} }) : undef;
    my $endpoint = sprintf("%s/%s", $self->base_url, $args->{resource});

    $content = $args->{content_str} if $args->{content_str};

    foreach (qw/id_0 endpoint id_1 extra id_2 id_3/) {
        $endpoint .= sprintf("/%s", $args->{$_}) if $args->{$_};
    }

    $endpoint .= $args->{query} if $args->{query};

    $args->{method} = uc($args->{method});

    my $request = HTTP::Request->new(
        $args->{method} => $endpoint,
        $self->_get_http_headers($args->{method}, $content),
        $content,
    );

    my $resp = $self->user_agent->request($request);

    return $resp->is_success
        ? decode_json($resp->decoded_content)
        : $resp->status_line;
}

################################################################################

sub _call {
    my $self = shift;
    my $args = shift;
    
    my $content  = $args->{content} ? encode_json($args->{content}) : undef;
    my $endpoint = sprintf("%s/%s", $self->base_url, $args->{resource});

    $content = encode_json({ content => $args->{content_str} }) if $args->{content_str};

    foreach (qw/id_0 endpoint id_1 extra id_2 id_3/) {
        $endpoint .= sprintf("/%s", $args->{$_}) if $args->{$_};
    }

    $endpoint .= $args->{query} if $args->{query};
    p $endpoint;
    p $content;
    p $args->{method};

    $args->{method} = uc $args->{method};

    my $request = HTTP::Request->new(
        $args->{method} => $endpoint,
        $self->_get_http_headers($args->{method}, $content, $args->{content_type}),
        $content,
    );

    my $resp = $self->user_agent->request($request);

    return $resp->is_success
        ? decode_json($resp->decoded_content)
        : $resp->status_line;
}

sub _get_http_headers {
    my $self         = shift;
    my $method       = shift;
    my $content      = shift;
    my $content_type = shift // 'application/json';

    my $content_length = length($content) // 0;

    my %args = (
        'Authorization' => sprintf("Bot %s", $self->auth_token),
        'Content-Type'  => $content_type,
    );

    $args{'Content-Length'} = $content_length if $method =~ /^(PUT|PATCH|POST)$/;

    return HTTP::Headers->new(%args);
}

sub _query_string {
    my $self  = shift;
    my $names = shift;
    my $args  = shift;

    my (@parts, $str);

    foreach (@{$names}) {
        push @parts, sprintf("%s=%s", $_, $args->{$_}) if $args->{$_};
    }

    $str = '?' . join '&', @parts if @parts;

    return $str;
}

################################################################################

sub _build_user_agent {
    my $self = shift;

    my $ua = LWP::UserAgent->new();

    $ua->timeout(10);
    $ua->max_redirect(0);
    $ua->agent($self->ua_string);
    $ua->env_proxy;

    return $ua;
}

sub _build_gateway { shift->_build_resource('Gateway'); }
sub _build_channel { shift->_build_resource('Channel'); }

sub _build_resource {
    my $self     = shift;
    my $resource = shift;

    my $name = 'Discord::REST::'.$resource;

    return $name->new({
        auth_token => $self->auth_token,
        ua_string  => $self->ua_string,
    });
}

################################################################################

no Moose;
1;

