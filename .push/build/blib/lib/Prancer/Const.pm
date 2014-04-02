package Prancer::Const;

use strict;
use warnings FATAL => 'all';

use constant OK => 200;
use constant REDIRECT => 302;
use constant AUTH_REQUIRED => 401;
use constant FORBIDDEN => 403;
use constant NOT_FOUND => 404;
use constant SERVER_ERROR => 500;

use constant HTTP_CONTINUE => 100;
use constant HTTP_SWITCHING_PROTOCOLS => 101;

use constant HTTP_OK => 200;
use constant HTTP_CREATED => 201;
use constant HTTP_ACCEPTED => 202;
use constant HTTP_NON_AUTHORITATIVE => 203;
use constant HTTP_NO_CONTENT => 204;
use constant HTTP_RESET_CONTENT => 205;
use constant HTTP_PARTIAL_CONTENT => 206;

use constant HTTP_MULTIPLE_CHOICES => 300;
use constant HTTP_MOVED_PERMANENTLY => 301;
use constant HTTP_MOVED_TEMPORARILY => 302;
use constant HTTP_FOUND => 302;
use constant HTTP_SEE_OTHER => 303;
use constant HTTP_NOT_MODIFIED => 304;
use constant HTTP_USE_PROXY => 305;
use constant HTTP_TEMPORARY_REDIRECT => 307;
use constant HTTP_PERMAMENT_REDIRECT => 308;

use constant HTTP_BAD_REQUEST => 400;
use constant HTTP_UNAUTHORIZED => 401;
use constant HTTP_PAYMENT_REQUIRED => 402;
use constant HTTP_FORBIDDEN => 403;
use constant HTTP_NOT_FOUND => 404;
use constant HTTP_METHOD_NOT_ALLOWED => 405;
use constant HTTP_NOT_ACCEPTABLE => 406;
use constant HTTP_PROXY_AUTHENTICATION_REQUIRED => 407;
use constant HTTP_REQUEST_TIME_OUT => 408;
use constant HTTP_CONFLICT => 409;
use constant HTTP_GONE => 410;
use constant HTTP_LENGTH_REQUIRED => 411;
use constant HTTP_PRECONDITION_FAILED => 412;
use constant HTTP_REQUEST_ENTITY_TOO_LARGE => 413;
use constant HTTP_REQUEST_URI_TOO_LARGE => 414;
use constant HTTP_UNSUPPORTED_MEDIA_TYPE => 415;
use constant HTTP_RANGE_NOT_SATISFIABLE => 416;
use constant HTTP_EXPECTATION_FAILED => 417;
use constant HTTP_UPGRADE_REQUIRED => 426; # RFC 2817
use constant HTTP_PRECONDITION_REQUIRED => 428;
use constant HTTP_TOO_MANY_REQUESTS => 429; # RFC 6585
use constant HTTP_REQUEST_HEADER_TOO_LARGE => 431; # RFC 6585

use constant HTTP_INTERNAL_SERVER_ERROR => 500;
use constant HTTP_NOT_IMPLEMENTED => 501;
use constant HTTP_BAD_GATEWAY => 502;
use constant HTTP_SERVICE_UNAVAILABLE => 503;
use constant HTTP_GATEWAY_TIME_OUT => 504;
use constant HTTP_VERSION_NOT_SUPPORTED => 505;

1;

=head1 NAME

Prancer::Const

=head1 SYNOPSIS

    use Prancer::Const;

    sub handle {
        my $self = shift;

        mount('GET', '/', sub {

            ...

            context->finalize(Prancer::Const::OK);
        });

        dispatch;
    }

=head1 COMMONLY USED ATTRIBUTES

=over 4

=item Prancer::Const::OK

Alias for C<Prancer::Const::HTTP_OK>.

=item Prancer::Const::REDIRECT

Alias for C<Prancer::Const::HTTP_MOVED_TEMPORARILY>.

=item Prancer::Const::AUTH_REQUIRED

Alias for C<Prancer::Const::HTTP_UNAUTHORIZED>.

=item Prancer::Const::FORBIDDEN

Alias for C<Prancer::Const::HTTP_FORBIDDEN>.

=item Prancer::Const::NOT_FOUND

Alias for C<Prancer::Const::HTTP_NOT_FOUND>.

=item Prancer::Const::SERVER_ERROR

Alias for C<Prancer::Const::HTTP_INTERNAL_SERVER_ERROR>.

=back

=head1 1xx INFORMATIONAL

=over 4

=item Prancer::Const::HTTP_CONTINUE (100)

This means that the server has received the request headers, and that the
client should proceed to send the request body (in the case of a request for
which a body needs to be sent; for example, a POST request). If the request
body is large, sending it to a server when a request has already been rejected
based upon inappropriate headers is inefficient. To have a server check if the
request could be accepted based on the request's headers alone, a client must
send C<Expect: 100-continue> as a header in its initial request and check if a
C<100 Continue> status code is received in response before continuing (or
receive C<417 Expectation Failed> and not continue).

=item Prancer::Const::HTTP_SWITCHING_PROTOCOLS (101)

This means the requester has asked the server to switch protocols and the
server is acknowledging that it will do so.

=back

=head1 2xx SUCCESS

=over 4

=item Prancer::Const::HTTP_OK (200)

Standard response for successful HTTP requests. The actual response will depend
on the request method used. In a GET request, the response will contain an
entity corresponding to the requested resource. In a POST request the response
will contain an entity describing or containing the result of the action.

=item Prancer::Const::HTTP_CREATED (201)

The request has been fulfilled and resulted in a new resource being created.

=item Prancer::Const::HTTP_ACCEPTED (202)

The request has been accepted for processing, but the processing has not been
completed. The request might or might not eventually be acted upon, as it might
be disallowed when processing actually takes place.

=item Prancer::Const::HTTP_NON_AUTHORITATIVE (203)

The server successfully processed the request, but is returning information
that may be from another source.

=item Prancer::Const::HTTP_NO_CONTENT (204)

The server successfully processed the request, but is not returning any
content. Usually used as a response to a successful delete request.

=item Prancer::Const::HTTP_RESET_CONTENT (205)

The server successfully processed the request, but is not returning any
content. Unlike a 204 response, this response requires that the requester reset
the document view.

=item Prancer::Const::HTTP_PARTIAL_CONTENT (206)

The server is delivering only part of the resource due to a range header sent
by the client. The range header is used by tools like wget to enable resuming
of interrupted downloads, or split a download into multiple simultaneous
streams.

=back

=head1 3xx REDIRECTION

=over 4

=item Prancer::Const::HTTP_MULTIPLE_CHOICES (300)

Indicates multiple options for the resource that the client may follow. It, for
instance, could be used to present different format options for video, list
files with different extensions, or word sense disambiguation.

=item Prancer::Const::HTTP_MOVED_PERMANENTLY (301)

This and all future requests should be directed to the given URI.

=item Prancer::Const::HTTP_MOVED_TEMPORARILY (302)

This is an example of industry practice contradicting the standard. The
HTTP/1.0 specification (RFC 1945) required the client to perform a temporary
redirect (the original describing phrase was "Moved Temporarily"), but popular
browsers implemented 302 with the functionality of a 303 See Other. Therefore,
HTTP/1.1 added status codes 303 and 307 to distinguish between the two
behaviors. However, some Web applications and frameworks use the 302 status
code as if it were the 303.

=item Prancer::Const::HTTP_FOUND (302)

This is the same as C<Prancer::Const::HTTP_MOVED_TEMPORARILIY>.

=item Prancer::Const::HTTP_SEE_OTHER (303)

The response to the request can be found under another URI using a GET method.
When received in response to a POST (or PUT/DELETE), it should be assumed that
the server has received the data and the redirect should be issued with a
separate GET message

=item Prancer::Const::HTTP_NOT_MODIFIED (304)

Indicates that the resource has not been modified since the version specified
by the request headers If-Modified-Since or If-Match. This means that there is
no need to retransmit the resource, since the client still has a previously
downloaded copy.

=item Prancer::Const::HTTP_USE_PROXY (305)

The requested resource is only available through a proxy, whose address is
provided in the response. Many HTTP clients (such as Mozilla and Internet
Explorer) do not correctly handle responses with this status code, primarily
for security reasons.

=item Prancer::Const::HTTP_TEMPORARY_REDIRECT (307)

In this case, the request should be repeated with another URI; however, future
requests should still use the original URI. In contrast to how 302 was
historically implemented, the request method is not allowed to be changed when
reissuing the original request. For instance, a POST request should be repeated
using another POST request.

=item Prancer::Const::HTTP_PERMAMENT_REDIRECT (308)

The request, and all future requests should be repeated using another URI. 307
and 308 (as proposed) parallel the behaviors of 302 and 301, but do not allow
the HTTP method to change. So, for example, submitting a form to a permanently
redirected resource may continue smoothly.

=back

=head1 4xx CLIENT ERROR

=over 4

=item Prancer::Const::HTTP_BAD_REQUEST (400)

The request cannot be fulfilled due to bad syntax.

=item Prancer::Const::HTTP_UNAUTHORIZED (401)

Similar to C<403 Forbidden>, but specifically for use when authentication is
required and has failed or has not yet been provided. The response must include
a C<WWW-Authenticate> header field containing a challenge applicable to the
requested resource. See Basic access authentication and Digest access
authentication.

=item Prancer::Const::HTTP_PAYMENT_REQUIRED (402)

Reserved for future use. The original intention was that this code might be
used as part of some form of digital cash or micropayment scheme, but that has
not happened, and this code is not usually used. YouTube uses this status if a
particular IP address has made excessive requests, and requires the person to
enter a CAPTCHA.

=item Prancer::Const::HTTP_FORBIDDEN (403)

The request was a valid request, but the server is refusing to respond to it.
Unlike a C<401 Unauthorized> response, authenticating will make no difference.
On servers where authentication is required, this commonly means that the
provided credentials were successfully authenticated but that the credentials
still do not grant the client permission to access the resource (e.g., a
recognized user attempting to access restricted content).

=item Prancer::Const::HTTP_NOT_FOUND (404)

The requested resource could not be found but may be available again in the
future. Subsequent requests by the client are permissible.

=item Prancer::Const::HTTP_METHOD_NOT_ALLOWED (405)

A request was made of a resource using a request method not supported by that
resource; for example, using GET on a form which requires data to be presented
via POST, or using PUT on a read-only resource.

=item Prancer::Const::HTTP_NOT_ACCEPTABLE (406)

The requested resource is only capable of generating content not acceptable
according to the C<Accept> headers sent in the request.

=item Prancer::Const::HTTP_PROXY_AUTHENTICATION_REQUIRED (407)

The client must first authenticate itself with the proxy.

=item Prancer::Const::HTTP_REQUEST_TIME_OUT (408)

The server timed out waiting for the request. According to W3 HTTP
specifications: "The client did not produce a request within the time that the
server was prepared to wait. The client MAY repeat the request without
modifications at any later time."

=item Prancer::Const::HTTP_CONFLICT (409)

Indicates that the request could not be processed because of conflict in the
request, such as an edit conflict in the case of multiple updates.

=item Prancer::Const::HTTP_GONE (410)

Indicates that the resource requested is no longer available and will not be
available again. This should be used when a resource has been intentionally
removed and the resource should be purged. Upon receiving a 410 status code,
the client should not request the resource again in the future. Clients such as
search engines should remove the resource from their indices. Most use cases do
not require clients and search engines to purge the resource, and a "404 Not
Found" may be used instead.

=item Prancer::Const::HTTP_LENGTH_REQUIRED (411)

The request did not specify the length of its content, which is required by the
requested resource.

=item Prancer::Const::HTTP_PRECONDITION_FAILED (412)

The server does not meet one of the preconditions that the requester put on the
request.

=item Prancer::Const::HTTP_REQUEST_ENTITY_TOO_LARGE (413)

The request is larger than the server is willing or able to process.

=item Prancer::Const::HTTP_REQUEST_URI_TOO_LARGE (414)

The URI provided was too long for the server to process. Often the result of
too much data being encoded as a query-string of a GET request, in which case
it should be converted to a POST request.

=item Prancer::Const::HTTP_UNSUPPORTED_MEDIA_TYPE (415)

The request entity has a media type which the server or resource does not
support. For example, the client uploads an image as C<image/svg+xml>, but the
server requires that images use a different format.

=item Prancer::Const::HTTP_RANGE_NOT_SATISFIABLE (416)

The client has asked for a portion of the file, but the server cannot supply
that portion. For example, if the client asked for a part of the file that lies
beyond the end of the file.

=item Prancer::Const::HTTP_EXPECTATION_FAILED (417)

The server cannot meet the requirements of the Expect request-header field.

=item Prancer::Const::HTTP_UPGRADE_REQUIRED (426)

The client should switch to a different protocol such as TLS/1.0.

=item Prancer::Const::HTTP_PRECONDITION_REQUIRED (428)

The origin server requires the request to be conditional. Intended to prevent
"the 'lost update' problem, where a client GETs a resource's state, modifies
it, and PUTs it back to the server, when meanwhile a third party has modified
the state on the server, leading to a conflict."

=item Prancer::Const::HTTP_TOO_MANY_REQUESTS (429)

The user has sent too many requests in a given amount of time. Intended for use
with rate limiting schemes.

=item Prancer::Const::HTTP_REQUEST_HEADER_TOO_LARGE (431)

The server is unwilling to process the request because either an individual
header field, or all the header fields collectively, are too large.

=back

=head1 5xx SERVER ERROR

=over 4

=item Prancer::Const::HTTP_INTERNAL_SERVER_ERROR (500)

A generic error message, given when no more specific message is suitable.

=item Prancer::Const::HTTP_NOT_IMPLEMENTED (501)

The server either does not recognize the request method, or it lacks the
ability to fulfill the request. Usually this implies future availability (e.g.,
a new feature of a web-service API).

=item Prancer::Const::HTTP_BAD_GATEWAY (502)

The server was acting as a gateway or proxy and received an invalid response
from the upstream server.

=item Prancer::Const::HTTP_SERVICE_UNAVAILABLE (503)

The server is currently unavailable (because it is overloaded or down for
maintenance). Generally, this is a temporary state. Sometimes, this can be
permanent as well on test servers.

=item Prancer::Const::HTTP_GATEWAY_TIME_OUT (504)

The server was acting as a gateway or proxy and did not receive a timely
response from the upstream server.

=item Prancer::Const::HTTP_VERSION_NOT_SUPPORTED (505)

The server does not support the HTTP protocol version used in the request.

=back

=head1 CREDITS

This documentation was copied almost entirely from L<Wikipedia's documentation
on HTTP codes|http://en.wikipedia.org/wiki/Http_codes> and is freely available
under L<Creative Commons Attribution-ShareAlike License|http://creativecommons.org/licenses/by-sa/3.0/>.

=cut
