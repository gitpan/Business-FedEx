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
'Sender_FedEx_Express_Account_Number' => '248904968',
'Meter_Number' => '1147026',
'Label_Type' => '1',
'Label_Printer_Type' => '1',
'Label_Media_Type' => '5',
'Ship_Date' => '20020828',
'Customs_Declared_Value_Currency_Type' => 'USD',
'Package_Total' => 1
) or die $t->errstr;

$t->transaction() or die $t->errstr;

$t->label("myLabel.png");

