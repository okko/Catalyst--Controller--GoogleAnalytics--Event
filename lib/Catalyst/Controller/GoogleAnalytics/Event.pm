package Catalyst::Controller::GoogleAnalytics::Event;
use Moose;
use utf8;
use namespace::autoclean;
use Carp;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Catalyst::Controller::GoogleAnalytics::Event - Catalyst Controller to queue Google Analytics events and to send them to Google

=head1 DESCRIPTION

Catalyst Controller to queue Google Analytics events as the events happen and to send them to Google as soon as possible.

Add the call to events_js_output to every page footer. You can then push the events into the queue with the
push_event method and they will be sent to the Google Analytics as soon as possible. This makes it easy to track
funnel events on your site.

=head1 REQUIREMENTS

Google Analytics account, you can get yours at http://www.google.com/analytics/ for free. This component is tested
to work with Google Analytics API as of 2010-11-17.

Google Analytics tracking code installed, so that _gaq.push JavaScript function exists.
 
Needs $c->session to exist. You should use Catalyst::Plugin::Session or other capable plugin/component to provide that.

=head1 SEE ALSO

Google Analytics Event Tracking Guide http://code.google.com/apis/analytics/docs/tracking/eventTrackerGuide.html

=head1 LIMITATIONS

Event properties (category, action, label and value) are not escaped, so only use safe JavaScript values and avoid
the ' character in their values.

=head1 METHODS

=cut


=head2 push_event

    Pushes a new event to the session to be displayed later. Example usage:

    $c->forward('/googleanalytics/push_event', [{category => 'login', action => 'login_start'}]);

=cut

sub push_event :Private {
    my ( $self, $c, $event) = @_;

    croak 'Event category and event action required' if (!$event->{category} or !$event->{action});

    push @{ $c->session->{Catalyst_Controller_Google_Analytics_events} }, $event;
}

=head2 events_js_output

    Joins all GA events into a printable javascript snippet. Call this in the
    footer of all pages.

    Sample usage with HTML::Mason: <% $c->controller('GoogleAnalytics')->events_js_output($c) |n %>

=cut

sub events_js_output :Private {
    my ($self, $c) = @_;
    # Return empty if nothing in the queue
    return '' if (ref($c->session->{Catalyst_Controller_Google_Analytics_events}) ne 'ARRAY' or scalar(@{ $c->session->{Catalyst_Controller_Google_Analytics_events} })==0);

    my $output = qq{<script type="text/javascript">\n};
    while (my $event = shift @{ $c->session->{Catalyst_Controller_Google_Analytics_events} }) {
        $output .= "_gaq.push(['_trackEvent'"
            . ", '". $event->{category} ."'"
            . ", '". $event->{action}   ."'"
        ;
        $output .= ", '".$event->{label}."'" if ($event->{label});
        $output .= ", '".$event->{value}."'" if ($event->{value});
        $output .= "]); ";
    }
    $output .= qq{\n</script>\n};
}

__PACKAGE__->meta->make_immutable;

1;
