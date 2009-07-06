package Catalyst::View::Component::ESI;

use strict;
use Moose::Role;
 
requires 'process';

use LWP::UserAgent;

=head1 NAME

Catalyst::View::Component::ESI - Include ESI in your templates

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  package MyApp::View::TT;
  use Moose;

  extends 'Catalyst::View::TT';
  with 'Catalyst::View::Component::ESI';

  __PACKAGE__->config( LWP_OPTIONS => { option1 => 1} );

Then, somewhere in your templates:

  <esi:include src="http://www.google.com/"/>

=head1 DESCRIPTION

C<Catalyst::View::Component::ESI> allows you to include external content in your
templates. It's implemented as a 
L<Moose::Role|Moose::Role>, so using L<Moose|Moose> in your view is required.

Configuration file example:

  <View::TT>
    <LWP_OPTIONS>
      option1 value
    </LWP_OPTIONS>
	pass_cookies 1
  </View::TT>

=cut

has '_ua' => (is => 'rw', isa => 'LWP::UserAgent', lazy_build => 1);

sub _build__ua {
	my $self = shift;
	
	my %options;
	%options = %{$self->config->{LWP_OPTIONS}} if ($self->config->{LWP_OPTIONS});
	my $ua = LWP::UserAgent->new( %options );
	return $ua;
}

around 'process' => sub {
	my $orig = shift;
	my $self = shift;
	my ($c) = @_;
	my $ret = $self->$orig(@_);
	my $body = $c->res->body;

	while ($body =~ qr#(<esi:include src="([^"]+)"[^>]*/>)#) {
		my $esi = $1;
		my $url = $2;
		
		my %options;
		# TODO: Have configurable url rewrite rules
		if (($self->config->{pass_cookies})&&($c->request->headers->{cookie})) {
			$options{cookie} = $c->request->headers->{cookie};
		}
		
		my $cont = $self->_ua->get($url,%options)->content;
		
		# TODO: Fix content, and take out the things not supposed to be there?
		
		$body =~ s/\Q$esi\E/$cont/g;
	}
	
	$c->res->body($body);
	return $ret;
};

1;
