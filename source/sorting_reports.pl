use POSIX qw(strftime);

sub load_from_file{

	@results = ();

	open(IFILE, "<$_[0]") || die "Can't open $_[0]!";

	while(<IFILE>){
		chomp($_);		# remove pesky newline character(s)
		push(@results, $_);
	}

	close(IFILE);

	return @results;

}

@females = load_from_file("females.txt");
@males = load_from_file("males.txt");
@surnames = load_from_file("surnames.txt");
@genders = ("FEMALE","MALE");
%employess = ();

for ( $employee= 0; $employee < 1000; $employee++ ){

	$identity = sprintf "E%05d", $employee + 1;
	$gender = $genders[rand @genders];
	$forename = $gender eq "MALE" ? $males[rand @males] : $females[rand @females];
	$surname = $surnames[rand @surnames];

	# random date of birth
	$minimum = time() - ( 65 * 365 * 24 * 60 * 60 );
	$maximum = time() - ( 16 * 365 * 24 * 60 * 60 );
	$dob = int($minimum + rand($maximum - $minimum));

	# random date of hire
	$minimum = $dob + ( 16 * 365 * 24 * 60 * 60 );
	$maximum = time();

	$doh = int($minimum + rand($maximum-$minimum));

	# dates are stored as epoch so they can be sorted on/by

	$employees{$identity} = {gender=>$gender, forename=>$forename, surname=>$surname, dob=>$dob, doh=>$doh};

}

# formats for reports
format HEAD1 =
@||||||||||||||||||||||||||||||||||||||||||||||||||||| @####
$title,$%
ID     Forename        Surname         DoB        DoH
------ --------------- --------------- ---------- ----------
.
format BODY1 = 
@<<<<< @<<<<<<<<<<<<<< @<<<<<<<<<<<<<< @||||||||| @|||||||||
$identity, $forename, $surname, $dob, $doh
.

select(STDOUT);
$^ = HEAD1;
$~ = BODY1;
$= = 13;	# page length including header

# output sorted by $identity
$counter = $-;
$title = "Top 10 by Identity";

foreach $identity ( sort { $a cmp $b } keys %employees ){
	$forename = $employees{$identity}{forename};
	$surname = $employees{$identity}{surname};
	$dob = strftime("%Y-%m-%d", localtime($employees{$identity}{dob}));
	$doh = strftime("%Y-%m-%d", localtime($employees{$identity}{doh}));
	write;
	last if ( $- == 0 );
}
print "\n";

# output sorted by date of birth descending
$title = "Top 10 by Date of Birth";
foreach $identity ( sort { $employees{$a}{dob} <=> $employees{$b}{dob} } keys %employees ){
	$forename = $employees{$identity}{forename};
	$surname = $employees{$identity}{surname};
	#($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($employees{$identity}{dob});
	$dob = strftime("%Y-%m-%d", localtime($employees{$identity}{dob}));
	#($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($employees{$identity}{doh});
	$doh = strftime("%Y-%m-%d", localtime($employees{$identity}{doh}));
	write;
	last if ( $- == 0 );
}
print "\n";

# output sorted by date of hire descending
$title = "Top 10 by Date of Hire";
foreach $identity ( sort { $employees{$a}{doh} <=> $employees{$b}{doh} } keys %employees ){
	$forename = $employees{$identity}{forename};
	$surname = $employees{$identity}{surname};
	#($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($employees{$identity}{dob});
	$dob = strftime("%Y-%m-%d", localtime($employees{$identity}{dob}));
	#($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($employees{$identity}{doh});
	$doh = strftime("%Y-%m-%d", localtime($employees{$identity}{doh}));
	write;
	last if ( $- == 0 );
}

format HEAD2 =
@||||||||||||||||||||||||||||||||||||||||||||||||||||| @####
$title,$%
Name                                     Occurances
---------------------------------------  -------------------
.
format BODY2 =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @##################
$name,$count
.

$^ = HEAD2;
$~ = BODY2;

# most popular forenames

%forenames = ();

foreach $identity ( keys %employees ){
	if ( exists($forenames{$employees{$identity}{forename}}) ){
		$forenames{$employees{$identity}{forename}} += 1;
	}else{
		$forenames{$employees{$identity}{forename}}  = 1;
	}
}

$title = "Top 10 Forenames";
foreach $forename ( sort { $forenames{$b} <=> $forenames{$a} } keys %forenames ){
	$name = $forename;
	$count = $forenames{$forename};
	write;
	last if ( $- == 0 );
}

# most popular surnames

%surnames = ();

foreach $identity ( keys %employees ){
	if ( exists($surnames{$employees{$identity}{surname}}) ){
		$surnames{$employees{$identity}{surname}} += 1;
	}else{
		$surnames{$employees{$identity}{surname}}  = 1;
	}
}

$title = "Top 10 Surnames";
foreach $surname ( sort { $surnames{$b} <=> $surnames{$a} } keys %surnames ){
	$name = $surname;
	$count = $surnames{$surname};
	write;
	last if ( $- == 0 );
}