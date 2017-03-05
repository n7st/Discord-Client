package Discord::REST;

use HTTP::Headers;
use HTTP::Request;
use JSON::XS;
use LWP::UserAgent;
use Moose;

################################################################################

has auth_token => (is => 'ro', isa => 'Str', required => 1);
has ua_string  => (is => 'ro', isa => 'Str', required => 1);

has base_url => (is => 'ro', isa => 'Str', default => 'https://discordapp.com/api');

has http_headers => (is => 'ro', isa => 'HTTP::Headers',          lazy_build => 1);
has user_agent   => (is => 'ro', isa => 'LWP::UserAgent',         lazy_build => 1);
#has gateway      => (is => 'ro', isa => 'Discord::REST::Gateway', lazy_build => 1);

################################################################################

sub call {
    my $self = shift;
    my $args = shift;

    my $content  = $args->{content} ? encode_json({ content => $args->{content} }) : undef;
    my $endpoint = sprintf("%s/%s", $self->base_url, $args->{resource});

    foreach (qw/id_0 endpoint id_1 extra id_2 id_3/) {
        $endpoint .= sprintf("/%s", $args->{$_}) if $args->{$_};
    }

    $endpoint .= $args->{query} if $args->{query};

    $args->{method} = uc($args->{method});

    my $request = HTTP::Request->new(
        $args->{method} => $endpoint,
        $self->_get_http_headers($args->{method}),
        $content,
    );

    my $resp = $self->user_agent->request($request);

    return $resp->is_success
        ? decode_json($resp->decoded_content)
        : $resp->status_line;
}

################################################################################

sub _get_http_headers {
    my $self   = shift;
    my $method = shift;

    my %args = (
        'Authorization'  => sprintf("Bot %s", $self->auth_token),
        'Content-Type'   => 'multipart/form-data',
    );

    $args{'Content-Length'} = 0 if $method eq 'PUT';

    return HTTP::Headers->new(%args);
}

sub _build_user_agent {
    my $self = shift;

    my $ua = LWP::UserAgent->new();

    $ua->timeout(10);
    $ua->max_redirect(0);
    $ua->agent($self->ua_string);
    $ua->env_proxy;

    return $ua;
}

################################################################################

no Moose;
1;

