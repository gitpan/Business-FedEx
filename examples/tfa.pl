use Business::FedEx;

my $t = Business::FedEx->new(host=>'127.0.0.1', port=>8190);

#tracking exaple
$t->set_data(
5000,
'Sender_FedEx_Express_Account_Number' => '248904968',
'Meter_Number' => '1147026',
'Tracking_Number'=>'836603877972',
) or die $t->errstr;

# send data to Fedex
$t->transaction() or die $t->errstr;

my $stuff= $t->hash_ret;

foreach (keys %$stuff) {
	print $_. ' => ' . $stuff->{$_} . "\n";
}

print $t->lookup('Signed_For');
print $t->lookup('Delivery_Date');