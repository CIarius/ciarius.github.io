The PIVOT clause allows you to transpose rows into columns, aggregating data in the process.

Here’s an example…

SELECT * FROM (SELECT region_id, category_name, list_price, quantity FROM inventory_valuation) 
PIVOT (
    SUM(list_price * quantity) 
    FOR category_name IN ('CPU','Video Card','RAM','Mother Board','Storage')
) 
WHERE region_id IN (2,3) 
ORDER BY region_id;

The output looks like this…

REGION		CPU		VIDEO CARD	RAM	Mother Board	Storage
2	14282537.46	39483585.32		3033963.71	16666538.45
3	9678837.83	10519058.96		3212773.43	10316989.16

Another example, counting how many of each job title report to each manager

SELECT * FROM (SELECT employee_id, manager_id, job_title FROM employees) 
PIVOT( 
    COUNT(employee_id) AS employee_count 
    FOR job_title 
IN ('Public Accountant', 'Accounting Manager', 'Administration Assistant', 'President', 'Administration Vice President', 'Accountant', 'Finance Manager', 'Human Resources Representative', 'Programmer', 'Marketing Manager', 'Marketing Representative', 'Public Relations Representative', 'Purchasing Clerk', 'Purchasing Manager', 'Sales Manager', 'Sales Representative', 'Shipping Clerk', 'Stock Clerk', 'Stock Manager')
) 
ORDER BY manager_id;
