-- sqlplus ot/Orcl1234@xepdb1 @"/opt/oracle/oradata/Custom Scripts/orders_between_dates.sql" $(date +%d-%b-%Y -d '-7 days') $(date +%d-%b-%Y)@"/opt/oracle/oradata/Custom Scripts/orders_between_dates.sql"
SET FEEDBACK OFF;
SET MARKUP CSV ON;
SET VERIFY OFF;
SPOOL "/opt/oracle/oradata/Custom~1/orders_between_dates.csv"
SELECT * FROM orders_detail WHERE order_date BETWEEN '&1' AND '&2';
SPOOL OFF;
EXIT;