package Business::FedEx::ShipRequest; #must be in Business/FedEx
use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
#version check

$VERSION = '0.20'; # $Id: ShipRequest.pm,v 1.1.1.1 2002/08/22 12:29:56 jay.powers Exp $
use Business::FedEx;
use Business::FedEx::Constants qw($FE_ER $FE_RE $FE_SE $FE_TT $FE_RQ); # get all the FedEx return codes

@ISA = ("Business::FedEx");

sub ship {
	my $self = shift;
	my $UTI = 2016;
	$self->set_data($UTI, @_);
	$self->transaction() or die $self->errstr;

}

sub track {
	my $self = shift;
	my $UTI = 5000;
	$self->set_data($UTI, @_);
	$self->transaction() or die $self->errstr;
}

sub rate {
	my $self = shift;
	my $UTI = 3004;
	$self->set_data($UTI, @_);
	$self->transaction() or die $self->errstr;

}
1;
__END__

=head1 NAME

Business::FedEx::ShipRequest - Shipping/Tracking Interface to FedEx

=head1 SYNOPSIS 

ShipRequest provides 3 methods to the FedEx module.  This will help with backward compatibility to
the previous version of Business::FedEx under the old FedEx API.

=head1 API

head1 EXAMPLE

use Business::FedEx::ShipRequest;


my $t = Business::FedEx::ShipRequest->new(host=>'127.0.0.1', port=>8190) or die $t->errstr;

$t->track('Sender_FedEx_Express_Account_Number' => '598904968',
'Meter_Number' => '8597026',
'Tracking_Number'=>'839583877972'
);

print "Date #" . $t->lookup('delivery_date') . "\n";

=head1 AUTHORS

Patrick Tully, ptully@avatartech.com

0.20 by Jay Powers, jay@vermonster.com

=head1 SEE ALSO

Business::FedEx

Business::FedEx::Constants

=cut