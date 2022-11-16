-- stock valuation (list price) by region, country, city, warehouse, category, and product

    SELECT 
        region_name, country_name, city, warehouse_name, category_name, SUM(list_price*quantity) 
    FROM 
        inventory_valuation 
    WHERE region_id IN (2,3) AND warehouse_id IS NOT NULL 
    GROUP BY 
        CUBE(region_name, country_name, city, warehouse_name, category_name)
    ORDER BY 
        region_name, country_name, city, warehouse_name, category_name
;

-- stock valuation (list price) by region

    SELECT 
        region_name, SUM(list_price*quantity) 
    FROM 
        inventory_valuation 
    WHERE region_id IN (2,3)
    GROUP BY 
        CUBE(region_name)
    ORDER BY 
        region_name
;
