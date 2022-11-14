#!/usr/bin/perl

use DBI;

# formats for reports
format HEAD =
@||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| @####
$title,$%
ID     Forename        Surname         Hired      Role
------ --------------- --------------- ---------- ------------------------------
.
format BODY = 
@<<<<< @<<<<<<<<<<<<<< @<<<<<<<<<<<<<< @||||||||| @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$identity, $forename, $surname, $doh, $role
.

select(STDOUT);
$^ 	= HEAD;		# format for report head
$~ 	= BODY;		# format for report body
$= 	= 32;		# page length including header
$title 	= "Employees";	# page title

# connect to Oracle...
$dbh = DBI->connect("dbi:Oracle:localhost/xepdb1","ot","Orcl1234");

# prepare and execute the SQL statement
$stm = $dbh->prepare("SELECT employee_id, first_name, last_name, hire_date, job_title FROM employees ORDER BY employee_id");
$stm->execute;

# retrieve the results
while(  my $ref = $stm->fetchrow_hashref() ) {
	$identity 	= $ref->{'EMPLOYEE_ID'};
	$forename 	= $ref->{'FIRST_NAME'};
	$surname 	= $ref->{'LAST_NAME'};
	$doh 		= $ref->{'HIRE_DATE'};
	$role 		= $ref->{'JOB_TITLE'};
	write;
}
exit;