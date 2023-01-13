/*

The first parameter for UTL_FILE.OPEN is an entry in dba_directories created...
SQL> CREATE OR REPLACE DIRECTORY CUSTOM_SCRIPT AS '/opt/oracle/oradata/Custom Scripts';

...and here's what you get for your money...
SQL> SELECT * FROM dba_directories WHERE directory_name = 'CUSTOM_SCRIPT';

Connect to SQLPLUS xepdb1 datbase with username ot and password/database Orcl1234@xepdb1

The script can be ran from the SQLPLUS command line...
@"/opt/oracle/oradata/Custom Scripts/populate-employees.sql"

...note that (in my case) Oracle is running in a Docker container using a persistent storage volume on my local machine...
CMD> docker run -d -p 1521:1521 -p 5500:5500 -e ORACLE_PWD=whatever --name=oracle-xe --volume C:\Development\Oracle:/opt/oracle/oradata container-registry.oracle.com/database/express:latest

ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MM-YYYY';

*/

SET SERVEROUTPUT ON;

DECLARE
	TYPE names IS VARRAY(1000) OF VARCHAR2(255);
	females names;
	males names;
	surnames names;
	employee employees%ROWTYPE;

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

	-- reset the employees table

	-- DELETE FROM employees;

	-- ALTER TABLE employees MODIFY(id GENERATED AS IDENTITY (START WITH 1));

	-- COMMIT;

	-- load values from files into arrays
	females := loadFromFile('CUSTOM_SCRIPT', 'females.txt');
	males := loadFromFile('CUSTOM_SCRIPT', 'males.txt');
	surnames := loadFromFile('CUSTOM_SCRIPT', 'surnames.txt');

	-- create 1000 random employee records
	FOR indx in 1..1000 LOOP

		-- assign a random gender
		-- employees(indx).gender := genders(DBMS_RANDOM.VALUE(1, genders.COUNT));
		SELECT id INTO employee.gender_id FROM (SELECT id FROM genders ORDER BY dbms_random.value) WHERE rownum = 1; 

		-- assign a random forename based on gender
		IF ( employee.gender_id = 2 ) THEN
			employee.forename := females(DBMS_RANDOM.VALUE(1, females.COUNT));
		ELSE
			employee.forename := males(DBMS_RANDOM.VALUE(1, males.COUNT));
		END IF;

		-- assign a random surname
		employee.surname := surnames(DBMS_RANDOM.VALUE(1, surnames.COUNT));

		-- an employee can be any age from 16 to 65 years of age
		employee.date_of_birth := randomDateInRange(
			SYSDATE - INTERVAL '65' YEAR,
			SYSDATE - INTERVAL '16' YEAR
		);

		-- an employee could have been hired any date since their sixteenth birthday
		employee.date_of_hire := randomDateInRange(
			employee.date_of_birth + INTERVAL '16' YEAR,
			SYSDATE
		);

		DBMS_OUTPUT.PUT_LINE(
			employee.forename 
			|| ' ' 
			|| employee.surname 
			|| ' ' 
			|| employee.date_of_birth 
			|| ' ' 
			|| employee.date_of_hire 
			|| ' age - ' 
			|| INT(( SYSDATE - employee.date_of_birth ) / 365) 
			|| ' service - ' 
			|| INT(( SYSDATE - employee.date_of_hire ) / 365) 
			|| ' hired at age - ' 
			|| INT(( employee.date_of_hire - employee.date_of_birth ) / 365)
		);

		INSERT INTO employees (gender_id, forename, surname, date_of_birth, date_of_hire) VALUES (employee.gender_id, employee.forename, employee.surname, employee.date_of_birth, employee.date_of_hire);

	END LOOP;

	-- make the longest served employee the chairman (department 2 is ADMINISTRATION)

	UPDATE employees SET role_id = 1, department_id = 2 WHERE id = (SELECT id FROM (SELECT id FROM employees ORDER BY date_of_hire ASC) WHERE rownum = 1);

	-- randomly assign between 30 and 50 employees to each department other than PRODUCTION

	FOR department IN (SELECT * FROM departments WHERE department <> 'PRODUCTION') 
	LOOP

		DBMS_OUTPUT.PUT_LINE(department.department);

		FOR employee IN (SELECT * FROM (SELECT * FROM employees WHERE department_id IS NULL AND role_id IS NULL ORDER BY DBMS_RANDOM.RANDOM) WHERE rownum <= ROUND(DBMS_RANDOM.VALUE(30, 50)))
		LOOP
			DBMS_OUTPUT.PUT_LINE(CHR(9) || employee.forename || ' ' || employee.surname);
			UPDATE employees SET department_id = department.id WHERE id = employee.id;  
		END LOOP;

		-- make the longest served employee the department's director

		UPDATE employees SET role_id = 2 WHERE id = (SELECT id FROM (SELECT * FROM employees WHERE department_id = department.id AND role_id IS NULL ORDER BY date_of_hire ASC) WHERE rownum = 1);

		-- make the next longest served employee the department's manager

		UPDATE employees SET role_id = 3 WHERE id = (SELECT id FROM (SELECT * FROM employees WHERE department_id = department.id AND role_id IS NULL ORDER BY date_of_hire ASC) WHERE rownum = 1);

		-- make the next longest served employee the department's professional

		UPDATE employees SET role_id = 4 WHERE id = (SELECT id FROM (SELECT * FROM employees WHERE department_id = department.id AND role_id IS NULL ORDER BY date_of_hire ASC) WHERE rownum = 1);

		-- make the next longest served employee department's skilled

		UPDATE employees SET role_id = 8 WHERE id = (SELECT id FROM (SELECT * FROM employees WHERE department_id = department.id AND role_id IS NULL ORDER BY date_of_hire ASC) WHERE rownum = 1);

		-- make the next longest served employee department's semi-skilled

		UPDATE employees SET role_id = 9 WHERE id = (SELECT id FROM (SELECT * FROM employees WHERE department_id = department.id AND role_id IS NULL ORDER BY date_of_hire ASC) WHERE rownum = 1);

		-- make the next longest served employee department's technican

		UPDATE employees SET role_id = 7 WHERE id = (SELECT id FROM (SELECT * FROM employees WHERE department_id = department.id AND role_id IS NULL ORDER BY date_of_hire ASC) WHERE rownum = 1);

		-- make the rest unskilled

		UPDATE employees SET role_id = 10 WHERE id IN (SELECT id FROM employees WHERE department_id = department.id AND role_id IS NULL);

		-- make anyone under eighteen an intern

		UPDATE employees SET role_id = 11 WHERE id IN (SELECT id FROM employees WHERE department_id = department.id AND ROUND((sysdate - date_of_birth)/365) < 18);

	END LOOP;

	-- assign all employees not assigned a department to production department

	UPDATE employees SET department_id = 1 WHERE department_id IS NULL;

	-- make the longest served employee the production department's director

	UPDATE employees SET role_id = 2 WHERE id = (SELECT id FROM (SELECT * FROM employees WHERE department_id = 1 AND role_id IS NULL ORDER BY date_of_hire ASC) WHERE rownum = 1);

	-- based on length of service...

	-- make every 100th production employee without a role a manager

	UPDATE employees SET role_id = 3 WHERE id IN (SELECT id FROM (SELECT id FROM employees WHERE department_id = 1 AND role_id IS NULL ORDER BY date_of_hire ASC) WHERE rownum < (SELECT ROUND(COUNT(1)/100) FROM employees WHERE department_id = 1 AND role_id IS NULL));

	-- make every  50th production employee without a role a supervisor

	UPDATE employees SET role_id = 5 WHERE id IN (SELECT id FROM (SELECT id FROM employees WHERE department_id = 1 AND role_id IS NULL ORDER BY date_of_hire ASC) WHERE rownum < (SELECT ROUND(COUNT(1)/50) FROM employees WHERE department_id = 1 AND role_id IS NULL));

	-- make every  25th production employee without a role a lead hand 

	UPDATE employees SET role_id = 6 WHERE id IN (SELECT id FROM (SELECT id FROM employees WHERE department_id = 1 AND role_id IS NULL ORDER BY date_of_hire ASC) WHERE rownum < (SELECT ROUND(COUNT(1)/25) FROM employees WHERE department_id = 1 AND role_id IS NULL));

	-- make every  10th production employee without a role a skilled employee

	UPDATE employees SET role_id = 8 WHERE id IN (SELECT id FROM (SELECT id FROM employees WHERE department_id = 1 AND role_id IS NULL ORDER BY date_of_hire ASC) WHERE rownum < (SELECT ROUND(COUNT(1)/10) FROM employees WHERE department_id = 1 AND role_id IS NULL));

	-- make every   5th production employee without a role a semi-skilled employee

	UPDATE employees SET role_id = 9 WHERE id IN (SELECT id FROM (SELECT id FROM employees WHERE department_id = 1 AND role_id IS NULL ORDER BY date_of_hire ASC) WHERE rownum < (SELECT ROUND(COUNT(1)/5) FROM employees WHERE department_id = 1 AND role_id IS NULL));

	-- make all the rest of the roleless production employees unskilled employees

	UPDATE employees SET role_id = 10 WHERE id IN (SELECT id FROM employees WHERE department_id = 1 AND role_id IS NULL);

	-- make all production employees under eighteen apprentices

	UPDATE employees SET role_id = 12 WHERE id IN (SELECT id FROM employees WHERE department_id = 1 AND ROUND((sysdate - date_of_birth)/365) < 18);

	COMMIT;

END; 
/  
