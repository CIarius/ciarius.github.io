/*

The first parameter for UTL_FILE.OPEN is an entry in dba_directories created...
SQL> CREATE OR REPLACE DIRECTORY CUSTOM_SCRIPT AS '/opt/oracle/oradata/Custom Scripts';

...and here's what you get for your money...
SQL> SELECT * FROM dba_directories WHERE directory_name = 'CUSTOM_SCRIPT';

Connect to SQLPLUS xepdb1 datbase with username ot and password/database Orcl1234@xepdb1

The script can be ran from the SQLPLUS command line...
@"/opt/oracle/oradata/Custom Scripts/employees.sql"

...note that (in my case) Oracle is running in a Docker container using a persistent storage volume on my local machine...
CMD> docker run -d -p 1521:1521 -p 5500:5500 -e ORACLE_PWD=whatever --name=oracle-xe --volume C:\Development\Oracle:/opt/oracle/oradata container-registry.oracle.com/database/express:latest

ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MM-YYYY';

*/
SET SERVEROUTPUT ON;
DECLARE
	TYPE EmployeeRecordType IS RECORD (
		forename	VARCHAR2(255),
		surname		VARCHAR2(255),
		gender		VARCHAR2(1),
		DateOfBirth	DATE,
		DateOfHire	DATE
	);
	TYPE EmployeeTable IS TABLE OF EmployeeRecordType INDEX BY BINARY_INTEGER;
	TYPE names IS VARRAY(1000) OF VARCHAR2(255);
	employees EmployeeTable;
	females names;
	males names;
	surnames names;
	genders names;

	FUNCTION loadFromFile(pathname IN VARCHAR2, filename IN VARCHAR2) 
	RETURN names IS
		results names := names();
		ifile UTL_FILE.FILE_TYPE;
		str VARCHAR2(255);
		counter INTEGER := 1;
	BEGIN 

		ifile := UTL_FILE.FOPEN(pathname, filename, 'R');

		LOOP
			-- need to handle the EOF exception
			BEGIN
				UTL_FILE.GET_LINE(ifile, str);
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					EXIT;
			END;
			results.extend;
			results(counter) := RTRIM(str, CHR(13));
			counter := counter + 1;
		END LOOP;

		UTL_FILE.FCLOSE(ifile);

		RETURN results;

	END;

	FUNCTION randomDateInRange(alpha IN DATE, omega IN DATE) RETURN DATE IS
	BEGIN
		RETURN alpha + DBMS_RANDOM.VALUE(0, omega - alpha);
	END;

BEGIN

	-- load values from files into arrays
	females := loadFromFile('CUSTOM_SCRIPT', 'females.txt');
	genders := loadFromFile('CUSTOM_SCRIPT', 'genders.txt');
	males := loadFromFile('CUSTOM_SCRIPT', 'males.txt');
	surnames := loadFromFile('CUSTOM_SCRIPT', 'surnames.txt');

	-- create 1000 random employee records
	FOR indx in 1..1000 LOOP

		-- assign a random gender
		employees(indx).gender := genders(DBMS_RANDOM.VALUE(1, genders.COUNT));

		-- assign a random forename based on gender
		IF ( employees(indx).gender = 'F' ) THEN
			employees(indx).forename := females(DBMS_RANDOM.VALUE(1, females.COUNT));
		ELSE
			employees(indx).forename := males(DBMS_RANDOM.VALUE(1, males.COUNT));
		END IF;

		-- assign a random surname
		employees(indx).surname := surnames(DBMS_RANDOM.VALUE(1, surnames.COUNT));

		-- an employee can be any age from 16 to 65 years of age
		employees(indx).DateOfBirth := randomDateInRange(
			SYSDATE - INTERVAL '65' YEAR,
			SYSDATE - INTERVAL '16' YEAR
		);

		-- an employee could have been hired any date since their sixteenth birthday
		employees(indx).DateOfHire := randomDateInRange(
			employees(indx).DateOfBirth + INTERVAL '16' YEAR,
			SYSDATE
		);

		DBMS_OUTPUT.PUT_LINE(
			employees(indx).forename 
			|| ' ' 
			|| employees(indx).surname 
			|| ' ' 
			|| employees(indx).DateOfBirth 
			|| ' ' 
			|| employees(indx).DateOfHire 
			|| ' age - ' 
			|| INT(( SYSDATE - employees(indx).DateOfBirth ) / 365) 
			|| ' service - ' 
			|| INT(( SYSDATE - employees(indx).DateOfHire ) / 365) 
			|| ' hired at age - ' 
			|| INT(( employees(indx).DateOfHire - employees(indx).DateOfBirth ) / 365)
		);

	END LOOP;

END; 
/  