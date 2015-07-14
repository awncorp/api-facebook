# ABSTRACT: Perl 5 API wrapper for Facebook.com
package API::Facebook;

use API::Facebook::Class;

extends 'API::Facebook::Client';

use Carp ();
use Scalar::Util ();

# VERSION

has access_token => (
    is       => 'rw',
    isa      => Str,
    required => 0,
);

has identifier => (
    is       => 'rw',
    isa      => Str,
    default  => 'API::Facebook (Perl)',
);

has version => (
    is       => 'rw',
    isa      => Str,
    default  => '2.4',
);

method AUTOLOAD () {
    my ($package, $method) = our $AUTOLOAD =~ /^(.+)::(.+)$/;
    Carp::croak "Undefined subroutine &${package}::$method called"
        unless Scalar::Util::blessed $self && $self->isa(__PACKAGE__);

    # return new resource instance dynamically
    return $self->resource($method, @_);
}

method BUILD () {
    my $identifier = $self->identifier;
    my $version    = $self->version;
    my $agent      = $self->user_agent;
    my $url        = $self->url;

    $agent->transactor->name($identifier);
    $url->path("/v$version");

    return $self;
}

method PREPARE ($ua, $tx, %args) {
    my $headers = $tx->req->headers;
    my $url     = $tx->req->url;

    # default headers
    $headers->header('Content-Type' => 'application/json');

    # access token parameter
    $url->query->merge(access_token => $self->access_token) if $self->access_token;
}

method action ($method, %args) {
    $method = uc($method || 'get');

    # execute transaction and return response
    return $self->$method(%args);
}

method create (%args) {
    # execute transaction and return response
    return $self->POST(%args);
}

method delete (%args) {
    # execute transaction and return response
    return $self->DELETE(%args);
}

method fetch (%args) {
    # execute transaction and return response
    return $self->GET(%args);
}

method resource (@segments) {
    # build new resource instance
    my $instance = __PACKAGE__->new(
        access_token => $self->access_token,
        debug        => $self->debug,
        fatal        => $self->fatal,
        retries      => $self->retries,
        timeout      => $self->timeout,
        user_agent   => $self->user_agent,
        identifier   => $self->identifier,
        version      => $self->version,

    );

    # resource locator
    my $url = $instance->url;

    # modify resource locator if possible
    $url->path(join '/', $self->url->path, @segments);

    # return resource instance
    return $instance;
}

method update (%args) {
    # execute transaction and return response
    return $self->PUT(%args);
}

1;

=encoding utf8

=head1 SYNOPSIS

    use API::Facebook;

    my $facebook = API::Facebook->new(
        access_token => 'ACCESS_TOKEN',
        identifier   => 'IDENTIFIER',
    );

    $facebook->debug(1);
    $facebook->fatal(1);

    my $feed = $facebook->me('feed');
    my $results = $feed->fetch;

    # after some introspection

    $feed->update( ... );

=head1 DESCRIPTION

This distribution provides an object-oriented thin-client library for
interacting with the Facebook (L<http://facebook.com>) API. For usage and
documentation information visit L<https://developers.facebook.com/docs/graph-api>.

=cut

=head1 THIN CLIENT

A thin-client library is advantageous as it has complete API coverage and
can easily adapt to changes in the API with minimal effort. As a thin-client
library, this module does not map specific HTTP requests to specific routines,
nor does it provide parameter validation, pagination, or other conventions
found in typical API client implementations, instead, it simply provides a
simple and consistent mechanism for dynamically generating HTTP requests.
Additionally, this module has support for debugging and retrying API calls as
well as throwing exceptions when 4xx and 5xx server response codes are
returned.

=cut

=head2 Building

    my $feed = $facebook->me('feed');

    $feed->action;          # GET   /me/feed
    $feed->action('head');  # HEAD  /me/feed
    $feed->action('patch'); # PATCH /me/feed

Building up an HTTP request object is extremely easy, simply call method names
which correspond to the API's path segments in the resource you wish to execute
a request against. This module uses autoloading and returns a new instance with
each method call. The following is the equivalent:

=head2 Chaining

    my $me = $facebook->resource('me');

    # or

    my $me   = $facebook->me;
    my $feed = $me->resource('feed');

    # then

    $feed->action('put', %args); # PUT /me/feed

Because each call returns a new API instance configured with a resource locator
based on the supplied parameters, reuse and request isolation are made simple,
i.e., you will only need to configure the client once in your application.

=head2 Fetching

    my $me = $facebook->me;

    # query-string parameters

    $me->fetch( query => { ... } );

    # equivalent to

    my $me = $facebook->resource('me');

    $me->action( get => ( query => { ... } ) );

This example illustrates how you might fetch an API resource.

=head2 Creating

    my $me = $facebook->me;

    # content-body parameters

    $me->create( data => { ... } );

    # query-string parameters

    $me->create( query => { ... } );

    # equivalent to

    $facebook->resource('me')->action(
        post => ( query => { ... }, data => { ... } )
    );

This example illustrates how you might create a new API resource.

=head2 Updating

    my $me = $facebook->me;
    my $feed = $me->resource('feed');

    # content-body parameters

    $feed->update( data => { ... } );

    # query-string parameters

    $feed->update( query => { ... } );

    # or

    my $feed = $facebook->me('feed');

    $feed->update( ... );

    # equivalent to

    $facebook->resource('me')->action(
        put => ( query => { ... }, data => { ... } )
    );

This example illustrates how you might update a new API resource.

=head2 Deleting

    my $me   = $facebook->me;
    my $feed = $me->resource('feed');

    # content-body parameters

    $feed->delete( data => { ... } );

    # query-string parameters

    $feed->delete( query => { ... } );

    # or

    my $feed = $facebook->me('feed');

    $feed->delete( ... );

    # equivalent to

    $facebook->resource('me')->action(
        delete => ( query => { ... }, data => { ... } )
    );

This example illustrates how you might delete an API resource.

=cut

=head2 Transacting

    my $feed = $facebook->resource('me', 'feed');

    my ($results, $transaction) = $feed->action( ... );

    my $request  = $transaction->req;
    my $response = $transaction->res;

    my $headers;

    $headers = $request->headers;
    $headers = $response->headers;

    # etc

This example illustrates how you can access the transaction object used
represent and process the HTTP transaction.

=cut

=param access_token

    $facebook->access_token;
    $facebook->access_token('ACCESS_TOKEN');

The access_token parameter should be set to an API access token associated with your account.

=cut

=param identifier

    $facebook->identifier;
    $facebook->identifier('IDENTIFIER');

The identifier parameter should be set to a string that identifies your app.

=cut

=attr debug

    $facebook->debug;
    $facebook->debug(1);

The debug attribute if true prints HTTP requests and responses to standard out.

=cut

=attr fatal

    $facebook->fatal;
    $facebook->fatal(1);

The fatal attribute if true promotes 4xx and 5xx server response codes to
exceptions, a L<API::Facebook::Exception> object.

=cut

=attr retries

    $facebook->retries;
    $facebook->retries(10);

The retries attribute determines how many times an HTTP request should be
retried if a 4xx or 5xx response is received. This attribute defaults to 1.

=cut

=attr timeout

    $facebook->timeout;
    $facebook->timeout(5);

The timeout attribute determines how long an HTTP connection should be kept
alive. This attribute defaults to 10.

=cut

=attr url

    $facebook->url;
    $facebook->url(Mojo::URL->new('https://graph.facebook.com'));

The url attribute set the base/pre-configured URL object that will be used in
all HTTP requests. This attribute expects a L<Mojo::URL> object.

=cut

=attr user_agent

    $facebook->user_agent;
    $facebook->user_agent(Mojo::UserAgent->new);

The user_agent attribute set the pre-configured UserAgent object that will be
used in all HTTP requests. This attribute expects a L<Mojo::UserAgent> object.

=cut

=method action

    my $result = $facebook->action($verb, %args);

    # e.g.

    $facebook->action('head', %args);    # HEAD request
    $facebook->action('options', %args); # OPTIONS request
    $facebook->action('patch', %args);   # PATCH request


The action method issues a request to the API resource represented by the
object. The first parameter will be used as the HTTP request method. The
arguments, expected to be a list of key/value pairs, will be included in the
request if the key is either C<data> or C<query>.

=cut

=method create

    my $results = $facebook->create(%args);

    # or

    $facebook->POST(%args);

The create method issues a C<POST> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=cut

=method delete

    my $results = $facebook->delete(%args);

    # or

    $facebook->DELETE(%args);

The delete method issues a C<DELETE> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=cut

=method fetch

    my $results = $facebook->fetch(%args);

    # or

    $facebook->GET(%args);

The fetch method issues a C<GET> request to the API resource represented by the
object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=cut

=method update

    my $results = $facebook->update(%args);

    # or

    $facebook->PUT(%args);

The update method issues a C<PUT> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=cut

=resource achievement

    $facebook->resource(param('achievement'));

The achievement resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/achievement>.

=cut

=resource achievement_type

    $facebook->resource(param('achievement_type'));

The achievement_type resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/achievement_type>.

=cut

=resource ad_campaign

    $facebook->resource(param('ad-campaign'));

The ad_campaign resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/marketing-api/reference/ad-campaign>.

=cut

=resource ad_campaign_group

    $facebook->resource(param('ad-campaign-group'));

The ad_campaign_group resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/marketing-api/reference/ad-campaign-group>.

=cut

=resource ad_image

    $facebook->resource(param('ad-image'));

The ad_image resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/marketing-api/reference/ad-image>.

=cut

=resource ad_label

    $facebook->resource(param('ad-label'));

The ad_label resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/marketing-api/reference/ad-label>.

=cut

=resource app_request

    $facebook->resource(param('app-request'));

The app_request resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/app-request>.

=cut

=resource application

    $facebook->resource(param('application'));

The application resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/application>.

=cut

=resource application_context

    $facebook->resource(param('application-context'));

The application_context resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/application-context>.

=cut

=resource friend_list

    $facebook->resource(param('friend-list'));

The friend_list resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/friend-list>.

=cut

=resource hashtag

    $facebook->resource(param('hashtag'));

The hashtag resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/hashtag>.

=cut

=resource life_event

    $facebook->resource(param('life-event'));

The life_event resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/life-event>.

=cut

=resource mailing_address

    $facebook->resource(param('mailing-address'));

The mailing_address resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/mailing-address>.

=cut

=resource offsite_pixel

    $facebook->resource(param('offsite-pixel'));

The offsite_pixel resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/offsite-pixel>.

=cut

=resource open_graph_context

    $facebook->resource(param('open-graph-context'));

The open_graph_context resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/open-graph-context>.

=cut

=resource page

    $facebook->resource(param('page'));

The page resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/page>.

=cut

=resource photo

    $facebook->resource(param('photo'));

The photo resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/photo>.

=cut

=resource place_tag

    $facebook->resource(param('place-tag'));

The place_tag resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/place-tag>.

=cut

=resource product_catalog

    $facebook->resource(param('product-catalog'));

The product_catalog resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/marketing-api/reference/product-catalog>.

=cut

=resource product_feed

    $facebook->resource(param('product-feed'));

The product_feed resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/product-feed>.

=cut

=resource product_feed_upload

    $facebook->resource(param('product-feed-upload'));

The product_feed_upload resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/product-feed-upload>.

=cut

=resource product_feed_upload_error

    $facebook->resource(param('product-feed-upload-error'));

The product_feed_upload_error resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/product-feed-upload-error>.

=cut

=resource product_group

    $facebook->resource(param('product-group'));

The product_group resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/product-group>.

=cut

=resource product_item

    $facebook->resource(param('product-item'));

The product_item resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/product-item>.

=cut

=resource product_set

    $facebook->resource(param('product-set'));

The product_set resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/product-set>.

=cut

=resource promotion_info

    $facebook->resource(param('promotion-info'));

The promotion_info resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/promotion-info>.

=cut

=resource user

    $facebook->resource(param('user'));

The user resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/user>.

=cut

=resource user_context

    $facebook->resource(param('user-context'));

The user_context resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/user-context>.

=cut

=resource video

    $facebook->resource(param('video'));

The video resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/video>.

=cut

=resource video_broadcast

    $facebook->resource(param('video-broadcast'));

The video_broadcast resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/video-broadcast>.

=cut

=resource video_list

    $facebook->resource(param('video-list'));

The video_list resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/video-list>.

=cut

