#!/usr/bin/env perl
use 5.016;
use common::sense;
use utf8::all;

# Use fast binary libraries
use EV;
use Web::Scraper::LibXML;
use YADA 0.039;

YADA->new(
    common_opts => {
        # Available opts @ http://curl.haxx.se/libcurl/c/curl_easy_setopt.html
        encoding        => '',
        followlocation  => 1,
        maxredirs       => 5,
    }, http_response => 1, max => 4,
)->append([qw[
	www.bbc.com
]] => sub {
    my ($self) = @_;
    return  if $self->has_error
        or not $self->response->is_success
        or not $self->response->content_is_html;

    # Declare the scraper once and then reuse it
    state $scraper = scraper {
        process q(html title), title => q(text);
        process q(a), q(links[]) => q(@href);
    };

    # Employ amazing Perl (en|de)coding powers to handle HTML charsets
    my $doc = $scraper->scrape(
        $self->response->decoded_content,
        $self->final_url,
    );

    printf qq(%-64s %s\n), $self->final_url, $doc->{title};

    # Enqueue links from the parsed page
    $self->queue->prepend([
        grep {
            $_->can(q(host)) and $_->scheme =~ m{^https?$}x
            and $_->host eq $self->initial_url->host
            and (grep { length } $_->path_segments) <= 3
        } @{$doc->{links} // []}
    ] => __SUB__);
})->wait;
__DATA__
