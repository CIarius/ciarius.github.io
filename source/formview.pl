#!C:\Strawberry\perl\bin\perl.exe

use CGI;
use CGI::Session;
use Config::Properties;
use Data::Dumper;
use DBD::Oracle qw(:ora_types);
use DBI;
use HTML::Template;
use strict;
use Switch;
use warnings;

$CGI::APPEND_QUERY_STRING = 1;		# append GET/POST parameters so Vars returns both
$CGI::POST_MAX = 1024;			# avoid DoS attacks by limiting the size of a POST

my $cgi = CGI->new;

# should have logged in so should have a cookie from which we get the session id
my $sid = $cgi->cookie('CGISESSID') || $cgi;

# create a session using the sid
my $session = CGI::Session->load("driver:File", $sid, {Directory=>'/tmp'}) or die CGI::Session->errstr();

# session parameters are stored in a file named for the session id, stored  in the server's /tmp directory 
my $username = $session->param('username');

# if any of these conditions apply we're going to redirect the client to the login page 
if ( ! defined $sid || $session->is_expired || ! defined $username ){
	print $cgi->redirect('login.pl');
	exit;	
}

# always do this regardless of its being a GET or a POST
print "Content-Type: text/html\n\n";

# get GET/POST parameters as a hash of name/value pairs
my $params = $cgi->Vars;

# convert all the %params keys to UC for consistency between the script, the template, and the stored procedure(s)

map { 
	if ( $_ =~ qr/[a-z]+/mp ){ 				# if the key contains any lowercase letters then...
		$params->{uc $_} = $params->{$_}; 	# 	create a new uppercase key with the same value as the lower
		delete($params->{$_}); 				# 	delete the lowercase key so there's no ambuguity in the hash
	}  										# end if
} keys %{$params};

my $table = uc $params->{'TABLE'};	# this is case sensitive in stored procedures	
delete($params->{'TABLE'});			# delete the table key/value pair from the hash

my $action = uc $params->{'ACTION'};	# this is case sensitive in stored procedures	
delete($params->{'ACTION'});			# delete the action key/value pair from the hash

my @columns = keys(%{$params});	# all field/column names sans TABLE and ACTION

# load the database properties from properties/database.properties

my $filename = sprintf("%s/properties/database.properties", $ENV{DOCUMENT_ROOT});

open my $pfh, '<', $filename or die "Unable to open $filename file!";

my $properties = Config::Properties->new();

$properties->load($pfh);

my $dsn = $properties->getProperty("database.dsn");

my $schema = uc $properties->getProperty("database.username");

# if we're not logged in as the DBA then we're using a proxy off of the DBA

if ( $username ne $schema ){
	$username = sprintf("%s[%s]", $schema, $username);
}

my $password = $properties->getProperty("database.password");

# get the database connection (one per session, auto commit disabled)

my $dbh = DBI->connect($dsn, $username, $password, { RaiseError => 1, AutoCommit => 0 }) || die(DBI->errstr());

# set the date format for the templates/procedures

$dbh->do("ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD'");

# retrieve primary and foreign key metadata for given schema/table

my $sql = "BEGIN $schema.retrieve_metadata('$schema', '$table', :CURSOR); END;";

my $sth = $dbh->prepare($sql);

$sth->bind_param_inout(":CURSOR", \my $ref, 0, {ora_type => ORA_RSET});

$sth->execute();

my $keys_meta_data = $ref->fetchall_hashref('COLUMN_NAME');

my @message;

if ( $ENV{'REQUEST_METHOD'} eq 'POST' ) {

	# estabish some common variables to draw upon while composing the appropriate SQL statement for $action

	#my @keys = keys(%{$keys_meta_data});	# key column names
	my @holders = ();			# values for placeholders

	# regardless of it's being an INSERT, UPDATE, or DELETE always use ? placeholdes for values
	# DBI will automatically escape these thus preventing the possibility of SQL injection attack

	switch ( $action ){

		case 'INSERT' {

			# INSERT INTO table (field, field,...) VALUES (?, ?,...)

			my $insertables;	# hash of params of non primary key columns

			while ( my ($key, $value) = each %{$params} ){
				if ( $keys_meta_data->{$key}->{'CONSTRAINT_TYPE'} ne 'P' ){
					$insertables->{$key} = $params->{$key};
				}
			}

			$sql = "INSERT INTO $schema.$table (" . join(', ', keys %{$insertables}) . ') VALUES (' . '?,' x ((keys %{$insertables}) - 1) . '?)';

			@holders = values(%{$insertables});

		}		

		case 'UPDATE' {

			# UPDATE table SET field = ? WHERE field = ? AND field = ?

			my $setters = '';	# the SET field = ? clause
			my $filters = '';	# the WHERE field = ? clause

			#my %values = %{$params};
			my @values = ();

			# compose the SQL UPDATE statement

			while ( my ($index, $column) = each @columns ){
				if ( $keys_meta_data->{$column}->{'CONSTRAINT_TYPE'} eq 'P' ){								# if the column is a primary key then
					$filters = "$filters $column = ? AND";													# 	add a placeholder to the WHERE clause
					push(@holders, $params->{$column});														# 	add the value of the key to the array of key values
					#delete(%values{$column});																#	delete the name/value pair from the params hash
				}else{																						# else
					$setters = $index != @columns - 1 ? "$setters $column = ?, " : "$setters $column = ? ";	# 	all other field(s) go in the SET clause
					push(@values, $params->{$column});														#	add the value to the list of placeholder values
				} 																							# end if
			}

			$sql = "UPDATE $schema.$table SET $setters WHERE $filters 1 = 1";					# add 1 = 1 to round out the trailing AND in the WHERE clause

			@holders = (@values, @holders);

		}

		case 'DELETE' {

			# DELETE FROM table WHERE field = ? AND field = ?

			$sql = "DELETE FROM $schema.$table WHERE ";

			while ( my ($index, $column) = each @columns ){
				$sql = $index != @columns - 1 ? "$sql $column = ? AND" : "$sql $column = ?";
			}

			@holders = values(%{$params});

		}

	}

	print "<p>$sql<p>@holders";
	
	# execute the SQL query, passing the appropriate values for the placeholders

	@message = ({MESSAGE => [{ level => 'green', title => 'Success', value => 'Your changes have been committed to the database.' }]});

	$sth = $dbh->prepare($sql);

	$sth->execute(@holders);

	$dbh->commit();

	if ( $action eq 'INSERT' ){
		$action = 'SELECT';
		$params->{$columns[0]} = $dbh->last_insert_id(undef, $schema, $table, $columns[0]);
		print "***** INSERT - $columns[0] = $params->{$columns[0]} *****";
	}

}

#if ( $ENV{'REQUEST_METHOD'} eq 'GET' ) {

	# compose a SQL SELECT statement from the QUERY_STRING name/value pairs (the first being the table name)
	# remembering to always use ? placeholdes as DBI will automatically escape these to prevent SQL injection

	my $record;

	if ( $action eq 'INSERT' ){

		$sql = "SELECT * FROM $schema.$table FETCH NEXT 1 ROWS ONLY";

		$sth = $dbh->prepare($sql);

		$sth->execute();

		$record = $sth->fetchrow_hashref;	# ref to hash of result record 

		# we need a blank record for an INSERT

		foreach my $key ( keys %{$record} ){
			$record->{$key} = '';
		}

	}else{

		$sql = "SELECT * FROM $schema.$table WHERE ";

		while ( my($index, $column) = each @columns ) {
			$sql = $index != keys(%{$params}) - 1 ? "$sql $column = ? AND " : "$sql $column = ?";
		}

		$sth = $dbh->prepare($sql);

		# get the record 

		print "<p>$sql";

		print "<p>", Dumper(values%{$params});

		$sth->execute(values%{$params});

		$record = $sth->fetchrow_hashref;	# ref to hash of result record 

	}

	# get the column metadata

	my $column_names = $sth->{NAME};	# ref to array of column names

	my $column_types = $sth->{TYPE};	# ref to array of column types

	my $html_type;				# the HTML input type of the column SQL data type

	my @fields;				# an array of hashes (one per input) to be passed to the template

	while ( my ($column_index, $column_name) = each @{$column_names} ) {

		# determine the HTML input type from the column's SQL data type

		switch ( @{$column_types}[$column_index] ) {
			case  3	{ $html_type = 'number'; }
			case  8	{ $html_type = 'number'; }
			case 12	{ $html_type = 'text'; }
			case 93	{ $html_type = 'date'; }
			else	{ $html_type = 'text'; }
		}

		# populate the array of field/input metadata hashes to be passed to the template

		switch( $keys_meta_data->{$column_name}->{'CONSTRAINT_TYPE'} ){

			# primary keys are immutable and so their inputs are readonly

			case 'P' {
				push(@fields, { $column_name => [{ column => $column_name, disabled => 'readonly', type => $html_type, value => $record->{$column_name} }]});
			}

			# foreign keys' inputs are a drop down of valid values

			case 'R' {

				# the value/label pairs for the given table and column are read from stored procedure DROPDOWN
				
				# any errors with uninitialized values, check the store procedure 'dropdown' has a handler for the table/colum

				$sql = "BEGIN $schema.dropdown('$table', '$column_name', :CURSOR); END;";

				$sth = $dbh->prepare($sql) or die $sth->errstr;

				$sth->bind_param_inout(":CURSOR", \my $rsh, 0, {ora_type => ORA_RSET}) or die $sth->errstr;

				$sth->execute() or die $sth->errstr;

				my $ref = $rsh->fetchall_arrayref();

				my @options = ();

				while ( my ($value, $array) = each @{$ref} ){
					my ($value, $label) = @{$array};
					if ( $record->{$column_name} eq $value ){
						push(@options, {'label'=>$label, selected => 'selected', 'value'=>$value});
					}else{
						push(@options, {'label'=>$label, 'value'=>$value});
					}
				}

				push(@fields, { $column_name => [{ column => $column_name, options => \@options }]});			

			}

			# all the rest are inputs of whatever data type the COLUMN is

			else {
				push(@fields, { $column_name => [{ column => $column_name, type => $html_type, value => $record->{$column_name} }]});
			}

		}

	}

	# load/open the HTML template in htdocs/templates

	$filename = sprintf("%s/templates/formview.tmpl", $ENV{DOCUMENT_ROOT});

	my $template = HTML::Template->new(filename => $filename, die_on_bad_params => 0);	# die_on_bad_params => 0 so we ignore 'Attempt to set nonexistent parameter' errors

	$template->param(FIELDS => \@fields);		# pass the array of hashes by reference
	$template->param(TABLE => $table);
	$template->param(HEADING => \@message);		# "<div class='w3-panel w3-red'><h3>Warning!</h3><p>$message</p></div>"
	$template->param(ACTION => $action);
 
	# send the template output to the client device (stdout)
	print $template->output;

	$sth->finish;

	$dbh->disconnect;

#}

exit;