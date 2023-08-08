#!C:\Strawberry\perl\bin\perl.exe

use strict;
use warnings;

use CGI;
use CGI::Session;
use Config::Properties;
use DBI;
use DBD::Oracle qw(:ora_types);
use HTML::Template;

# this script makes the following assumptions:
#
# 1. the name of a stored procedure is passed as QUERY_STRING parameter procedure=<somename>
# 2. the other QUERY_STRING parameters are in the same order as the stored procedure's parameters
# 3. the results of running the stored procedure are displayed using a template named for the stored procedure
# 4. the stored procedure will return ROW_NUMBER() OVER (ORDER BY <fieldname>,..) AS ROW_NUM to act as a hash key

my $cgi = new CGI;

# should have logged in so should have a cookie 
my $sid = $cgi->cookie('CGISESSID') || undef;

# create a session using the sid
my $session = CGI::Session->load("driver:File", $sid, {Directory=>'/tmp'}) or die CGI::Session->errstr();

# session parameters are stored in a file in the server's /tmp dir named for the session id
my $username = $session->param('username');
my $password = $session->param('password');

# if any of these conditions apply we're going to redirect the client to the login page 
if ( ! defined $sid || $session->is_expired || ! defined $username || ! defined $password ){
	print $cgi->redirect('login.pl');
	exit;	
}

# put this after the potential redirect so we don't get a Status: 302 Found Location:... message instead of an actual redirect
print "Content-Type: text/html\n\n";
 
# for testing purposes this can be run on the command line by modifying/uncommenting the following lines
# $ENV{'REQUEST_METHOD'} = 'GET';
# $ENV{'DOCUMENT_ROOT'} = 'C:/Apache24/htdocs';
# $ENV{'QUERY_STRING'} = 'procedure=sp_customer_orders&customer_id=99';

if ( $ENV{'REQUEST_METHOD'} eq "GET" ) {

	# load the database properties from properties/database.properties
	my $filename = sprintf("%s/properties/database.properties", $ENV{DOCUMENT_ROOT});
	open my $pfh, '<', $filename or die "Unable to open $filename file!";
	my $properties = Config::Properties->new();
	$properties->load($pfh);

	# get hash of QUERY_STRING name/value pairs
	my $pairs = $cgi->Vars();

	# capture the stored procedure name then remove it from the hash
	my $procedure = $pairs->{"procedure"};
	delete($pairs->{"procedure"});

	# create a list of placeholders for the stored procedure IN parameters
	my $params = "";
	foreach my $key ( keys %{$pairs} ){
		$params = sprintf("%s :%s, ", $params, $key);
	}

	# add a placeholder for the stored procedure's OUT cursor reference
	$params = sprintf("%s %s", $params, ":CURSOR");

	# construct the SQL statement to execute the stored procedure
	my $sql = sprintf("BEGIN %s(%s); END;", uc $procedure, $params);
	
	# get a connection to Oracle
	my $dbh = DBI->connect($properties->getProperty("database.dsn"), $session->param("username"), $session->param("password")) || die(DBI->errstr());

	# data comes from stored procedure that takes none or many IN parameters and has one OUT parameter the resultset reference
	my $sth = $dbh->prepare($sql);

	# assign values to the stored procedure call's parameter placeholders
	foreach my $key ( keys %{$pairs} ){
		$sth->bind_param(sprintf(":%s", $key), $pairs->{$key});
	}

	# finally, add the OUT parameter - the result set cursor reference - at the end of the list of IN parameters
	$sth->bind_param_inout(":CURSOR", \my $rsh, 0, {ora_type => ORA_RSET});

	$sth->execute();

	# every stored procedure needs to return ROW_NUM as a key for the recordset hash to preserve the ordering
	# this is accomplished as SELECT ROW_NUMBER() OVER (ORDER BY <fieldname>,..) AS ROW_NUM,... FROM
	my $ref = $rsh->fetchall_hashref('ROW_NUM');

	# $ref references a hash of hash references but templates need an array of hash references, so we need to convert
	# can't just use 'my @rows = values %{$ref};' because (here) values returns an unordered array of hash references
	my @rows = ();
	foreach my $key ( sort { $a <=> $b } keys %{$ref} ){
		push(@rows, $ref->{$key});
	}

	# load/open the HTML template in htdocs/templates
	$filename = sprintf("%s/templates/%s.tmpl", $ENV{DOCUMENT_ROOT}, $procedure);
	my $template = HTML::Template->new(filename => $filename, die_on_bad_params => 0);	# die_on_bad_params => 0 so we ignore errors re 'Attempt to set nonexistent parameter'

	# pass the array of hash references by reference
	$template->param(RESULTS => \@rows);
 
	# send the template output to the client device (stdout)
	print $template->output;

	$dbh->disconnect;

}else{

	# POST

}
