package Business::FedEx; #must be in Business/FedEx
use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@EXPORT_OK = qw(&connect &disconnect &transaction &set_data &label &lookup &hash_ret &required);
#version check
$VERSION = '0.20'; # $Id: FedEx.pm,v 1.1.1.1 2002/08/22 12:29:56 jay.powers Exp $

use Business::FedEx::Constants qw($FE_ER $FE_RE $FE_SE $FE_TT $FE_RQ); # get all the FedEx return codes
# Used to call the Win32 DLL provieded by Fedex.  
# Make sure this file 'FedExAPIclient.dll' is in your system32 dir
use Win32::API; 

sub new {
	my $proto = shift;	
	my $class = ref($proto) || $proto;
	my $self  = { 
				 host=>'127.0.0.1'
				,port=>8190
				,Debug=>0
				,@_ };
	bless ($self, $class);	
	$self->_init();	
	return $self;
}
# initialize method
sub _init {
	my $self = shift;
	my @arg_tmp = qw(P I P I I P I I);
	# Set up connections to FedexAPI	
	eval {
		$self->{FedExInit}					= new Win32::API("fedexapiclient", "FedExAPIInit", '[]', 'I');
		$self->{FedExAPITransaction} 		= new Win32::API("fedexapiclient", "FedExAPITransaction", \@arg_tmp, 'I');	
		$self->{FedExAPIRelease}			= new Win32::API("fedexapiclient", "FedExAPIRelease", '[]', 'I');
	};
	if ($@) {
	      print "Error initializing API: " . $@;
	      return 0;
	}
	return $self;
}
# Connect to the FedEx API
sub _connect {
	my $self = shift;
	my $ret = $self->{FedExInit}->Call();	
	# Check to make sure API initialized
	if ($ret != 0) {		
		$self->errstr("FEDEX API ERROR: Could not initialize FEDEX API: Return = ". $FE_ER->{$ret});
		return 0;
	}
	return 1;
}
# Disconnect from the FedEx API
sub _disconnect {
	my $self = shift;
	$self->{FedExAPIRelease}->Call();
	return 1;
}
# Send a call to FedEx
sub transaction {
	my $self = shift;
	if (@_) {
		$self->{sbuf} = shift;
	}
	if ($self->{UTI} eq '') { # Find the UTI
		my $tmp = $self->{sbuf};
		$tmp =~ s/0,"([0-9]*).*"/$1/;
		for my $utis (keys %$FE_TT) {
			 for (@{%$FE_TT->{$utis}}) {
				$self->{UTI} = $utis if ($_ eq $tmp);
			 }
		}
	}
	if (!$self->{sbuf}) {		
			$self->errstr("Error: You must provide shipping data.");
			return 0;
	}
	print "Sending ". $self->{sbuf} . "\n" if ($self->{Debug});
	my $bufferLength = length($self->{sbuf});
	my $rbuf = ' ' x 10000; # Set the buffer size for FedEx transaction
	my $actual_rbuf; # the actual bytes read in the recieve buffer
	$self->_connect();
	my $tret = $self->{FedExAPITransaction}->Call($self->{host}, $self->{port}, $self->{sbuf}, $bufferLength, $self->{UTI}, $rbuf, length($rbuf), \$actual_rbuf);
	# Check to make sure API was a success
	if ($tret < -1) {
			$self->errstr("FEDEX API ERROR: Could not initialize FEDEX API: Return $tret = ".$rbuf);
			return 0;
	}
	$self->_disconnect();
	$rbuf =~ s/\s+$//g; # get rid of the extra spaces
	$self->{rbuf} = $rbuf;	
	$self->_split_data();
	if ($self->{rHash}->{transaction_error_code}) {
		$self->errstr("FedEx TRANSACTION ERROR: " . $self->{rHash}->{transaction_error_message});
		return 0;
	}
	return 1;
}

sub set_data {
	my $self = shift;
	$self->{UTI} = shift;
	my %args = @_;
	if (!$self->{UTI}) {		
		$self->errstr("Error: You must provide a valid UTI.");
		return 0;
	}	
	$self->{sbuf} = '0,"' . $FE_TT->{$self->{UTI}}[0] . '"3025,"' . $FE_TT->{$self->{UTI}}[1].'"';
	foreach (keys %args) {
		#print $FE_SE->{lc($_)}. "\n";
		$self->{sbuf} .= join(',',$FE_SE->{lc($_)},'"'.$args{$_}.'"');
	}
	$self->{sbuf} .='99,""';
	return $self->{sbuf};
}

# here are some functions to deal with data from FedEx
sub _split_data {
	my $self = shift;
	my $count;
	my @field_data;
	($self->{rstring}, $self->{rbinary}) = split("188,\"", $self->{rbuf});
	$self->{rstring} =~ s/\s{2,}/ /g; # get rid of any extra spaces
	# Thank PTULLY for this.
	my @fedex_response = split(//, $self->{rstring});
	foreach(@fedex_response){
	   $field_data[$count] = $field_data[$count].$_;
	   if($field_data[$count] =~ /\d+,\".*\"$/){
			$count++;
	 }
	}
	print "Return String " . $self->{rstring} . "\n" if ($self->{Debug});
	foreach (@field_data) 
	{
		/([0-9]+),\"(.*)\"/; 
		#print $1 ." = " . $2 . "\n";
		$self->{rHash}->{$FE_RE->{$1}} = $2 if ($FE_RE->{$1});
	}
}

# array of all the required fields
sub required {
	my $self = shift;
	my $uti = shift;
	my @req;
	foreach (@{%$FE_RQ->{$uti}}) {
		push @req, $FE_RE->{$_};
	}
	return @req;
}
# print or create a label
sub label {
	my $self = shift;
	$self->{rbinary} =~ s/"99.*$// if ($self->{rbinary}); #"
	$self->{rbinary} =~ s/\%([0-9][0-9])/chr(hex("0x$1"))/eg if ($self->{rbinary});	
	if (@_) {
		my $file = shift;
		open(FILE, ">$file") or  die "Couldn't open $file:\n$!";
		binmode(FILE);
		print FILE $self->{rbinary};
		close(FILE);
		return 1;
	} else {
		return $self->{rbinary};
	}
}
#look up a value
sub lookup {
	my $self = shift;
	my $code = shift;
	print "Looking for " . lc($code) . "\n" if ($self->{Debug});
	return $self->{rHash}->{lc($code)};
}
# All the data from FedEx
sub rbuf {
	my $self = shift;
	$self->{rbuf} = shift if @_;
	return $self->{rbuf};
}
# Build a hash from the return data from FedEx
sub hash_ret {
	my $self = shift;
	return $self->{rHash};
}

sub errstr { 
	my $self = shift;
	$self->{errstr} = shift if @_;
	return $self->{errstr};
}

sub DESTROY {

}
1;
__END__

=head1 NAME

Fedex - Win32 FedEx Ship Manager API 

=head1 SYNOPSIS

  use Business::Fedex;
  
  my $t = Business::FedEx->new(host=>'127.0.0.1', port=>8190, Debug=>0);
  
  #tracking exaple
  $t->set_data(
  'UTI' => 5000,
  'Sender_FedEx_Express_Account_Number' => '#########',
  'Meter_Number' => '#######',
  'Tracking_Number'=>'836603877972',
  ) or die $t->errstr;
  
  # send data to Fedex
  $t->transaction() or die $t->errstr;  
  
  print $t->lookup('Signed_For');
  print $t->lookup('Delivery_Date');


=head1 DESCRIPTION

This module will allow transactions to be sent through the FedEx Ship Manager API.  
The API must be installed and running for this module to work.
At this point it is required to run this module in a Win32 environment.  
The FedEx API is distributed with a DLL "FedExAPIclient.dll" which is called via Win32::API.
Please make sure this file is copied into your system32 folder.

Please refer to the FedEx documentation at http://www.fedex.com/globaldeveloper/shipapi/
Here you will find more information about using the FedEx API.  You will need to know
what UTI to use to send a request.

The Universal Transaction Identifier (UTI) is a unique integral code that has been assigned to a 
given transaction type.
For example, the UTI of the tagged Transaction Type 021 (FedEx Express global Ship a Package Request) 
is 2016.

I have not included the proxy portion of the module.  So this is a Win32 ONLY module.
Soon, I will be releasing a version that will talk directly to FedEx's API via HTTP.


=head1 COMMON METHODS

The methods described in this section are available for all C<FedEx> objects.

=over 4

=item $t->set_data(UTI, $hash)

This method will accept a valid FedEx UTI number and a hash of values.  The first
arg must be a valid UTI. Using these values set_data will construct and return a 
valid FedEx request string.

=item $t->required(UTI)

Method to return the required fields for a given FedEx UTI.

=item $t->transaction()

Send transaction to FedEx.  Returns the full reply from FedEx

=item $t->label('someLabel.png')

This method will decode the binary image data from FedEx.  If nothing
is passed in the binary data string will be returned.

=item $t->lookup('tracking_number')

This method will return the value for an item returned from FedEx.  Refer to
the C<FedEx::Constant> $FE_RE hash to see all possible values. 

=item $t->rbuf()

Returns the undecoded string portion of the FedEx reply.

=item $t->hash_ret();

Returns a hash of the FedEx reply values

my $stuff= $t->hash_ret;

foreach (keys %$stuff) {
	print $_. ' => ' . $stuff->{$_} . "\n";
}

=back

=head1 EXAMPLE

use Business::FedEx;

my $t = Business::FedEx->new(host=>'127.0.0.1', port=>8190);

$t->set_data(2016,
'Sender_Company' => 'Vermonster LLC',
'Sender_Address_Line_1' => '312 Stuart St',
'Sender_City' => 'Boston',
'Sender_State' => 'MA',
'Sender_Postal_Code' => '02134',
'Recipient_Contact_Name' => 'Jay Powers',
'Recipient_Address_Line_1' => '44 Main Street',
'Recipient_City' => 'Boston',
'Recipient_State' => 'MA',
'Recipient_Postal_Code' => '02116',
'Recipient_Phone_Number' => '6173335555',
'Weight_Units' => 'LBS',
'Sender_Country_Code' => 'US',
'Recipient_Country' => 'US',
'Sender_Phone_Number' => '6175556985',
'Future_Day_Shipment' => 'Y',
'Packaging_Type' => '01',
'Service_Type' => '03',
'Total_Package_Weight' => '1.0',
'Sender_FedEx_Express_Account_Number' => '243454968',
'Meter_Number' => '1147026',
'Label_Type' => '1',
'Label_Printer_Type' => '1',
'Label_Media_Type' => '5',
'Ship_Date' => '20020822',
'Customs_Declared_Value_Currency_Type' => 'USD',
'Package_Total' => 1
) or die $t->errstr;

$t->transaction() or die $t->errstr;

$t->label("myLabel.png");

$t->lookup('Tracking_Number');


=head1 EXPORT

None by default.

=head1 AUTHORS

This module was originally developed by C<PTULLY> using the previous version
of the FedEx API. Since FedEx has released their new API this module has been
revised by Jay Powers C<JPOWERS>

Patrick Tully, ptully@avatartech.com

Jay Powers, jay@vermonster.com

=head1 SEE ALSO

Business::FedEx::Constants
Business::FedEx::ShipRequest

http://www.vermonster.com/perl

L<perl>.

=cut