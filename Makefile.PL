use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Business::FedEx',
    'ABSTRACT' => 'Fedex - Win32 FedEx Ship Manager API',
    'ABSTRACT_FROM' => 'FedEx.pm',
    'VERSION_FROM'	=> 'FedEx.pm', # finds $VERSION
    'PREREQ_PM'		=> {Win32::API=>0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Jay Powers <jay@vermonster.com>') : ()),
);
