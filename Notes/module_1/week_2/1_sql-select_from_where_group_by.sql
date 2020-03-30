SELECT 1;

-- I'm a comment
/*
 I'm a comment block
 */
SELECT 1; -- I'm a comment as well

/*
---------
-- Selecting a sample
--
-- Clauses:
-- SELECT
-- FROM
-- LIMIT
---------
*/

SELECT *
FROM olist.customers;

/* all of these work as well
SELECT * FROM olist.customers;
select * from olist.customers;
sElEcT * fRoM olist.customers;
 */

SELECT *
FROM olist.customers
LIMIT 100;

-- The SELECT clause is just a projection of the table. You can select any column, in any order, as many times you want
SELECT
    customer_state,
    customer_state,
    customer_state,
    customer_id,
    customer_unique_id
FROM olist.customers;


SELECT
    customer_id,
    customer_zip_code_prefix,
    customer_state
FROM olist.customers
LIMIT 100;


-- Use the ORDER BY clause to sort your output
SELECT *
FROM olist.orders
ORDER BY order_purchase_timestamp
LIMIT 1000;

SELECT *
FROM olist.orders
ORDER BY order_purchase_timestamp ASC -- ASC for ascending order
LIMIT 1000;

-- Retrieve the most expensive product:
SELECT
    product_id,
    price
FROM olist.order_items
ORDER BY price DESC
LIMIT 1; -- LIMIT limits your output to the top n rows

SELECT
    order_id,
    customer_id,
    order_status
FROM olist.orders
ORDER BY order_purchase_timestamp DESC -- DESC for descending order
LIMIT 1000;

-- As the SELECT clause is just a projection, you don't even need to add the column you are ordering by in the SELECT
-- It will sort based on the underlying data (which is what the FROM and WHERE clause specify)
SELECT
    order_id        AS order_identifier,
    customer_id     AS customer_identifier,
    order_status    AS order_status_string
FROM olist.orders
ORDER BY order_purchase_timestamp DESC
LIMIT 1000;

SELECT
    oo.order_id                 AS order_identifier,    -- use AS to specify Aliases
    oo.customer_id              AS customer_identifier,
    olist.orders.order_status   AS order_status_string
FROM olist.orders oo                                    -- the AS is not required, but the convention is to add the AS
                                                        -- for columns and omit it for tables
ORDER BY order_purchase_timestamp DESC
LIMIT 1000;

/*
---------
-- Filtering rows
--
-- Clauses:
-- WHERE
---------
*/
-- select only those orders that were place in Feb 2018
SELECT *
FROM olist.orders
WHERE order_purchase_timestamp >= '2018-02-01'
    AND order_purchase_timestamp < '2018-03-01'
LIMIT 1000;

-- only customers from 'BA'
SELECT *
FROM olist.customers
WHERE customer_state = 'BA'
LIMIT 100;

-- only customers from 'BA' and 'salvador'
SELECT *
FROM olist.customers
WHERE customer_state = 'BA'
    AND customer_city = 'salvador'
LIMIT 100;

-- only customers from 'BA' and 'salvador' that have a customer_id that starts with 'a'
SELECT *
FROM olist.customers
WHERE customer_state = 'BA'
    AND customer_city = 'salvador'
    AND customer_id LIKE 'a%'
LIMIT 100;

-- only customers from states 'BA' OR 'GO' and city = 'salvador' that have a customer_id that starts with 'a'
SELECT *
FROM olist.customers
WHERE (customer_state = 'BA'
    OR customer_state = 'GO') -- make sure to group conditions if you combine ANDs and ORs
    AND customer_id LIKE 'a%'
LIMIT 100;

SELECT *
FROM olist.customers
WHERE (customer_state = 'BA'
    OR customer_state = 'GO')
    AND customer_id LIKE 'a%';

SELECT *
FROM olist.customers
WHERE customer_state IN ('BA','GO')
    AND customer_id LIKE 'a%';

-- only get order_items that have a shipping_limit_date equal to '2017-05-17'
SELECT
    order_id,
    product_id,
    seller_id,
    shipping_limit_date,
    DATE(shipping_limit_date)
FROM olist.order_items
WHERE DATE(shipping_limit_date) = DATE('2017-05-17');

/*
---------
-- Column transformations
---------
*/

-- add a new column that states in which price category a product is
SELECT
    order_id,
    product_id,
    price
FROM olist.order_items
LIMIT 1000;

-- Transform the price column into price categories ('cheap', 'expensive')
SELECT
    order_id,
    product_id,
    price,
    IF(price < 100, 'cheap', 'expensive') AS price_category
FROM olist.order_items;

SELECT -- again, you don't have to select the price column if not needed. the transformation will still work
    order_id,
    product_id,
    IF(price < 100, 'cheap', 'expensive') AS price_category
FROM olist.order_items;

-- add an additional condition for 'medium' using nested IF statements
SELECT
    order_id,
    product_id,
    IF(price < 100, 'cheap', IF(price < 350, 'medium', 'expensive')) AS price_category
FROM olist.order_items;

-- rewrite as a case statement
SELECT
    order_id,
    product_id,
    CASE
        WHEN price < 100 THEN 'cheap'
        WHEN price < 350 THEN 'medium'
        ELSE 'expensive'
    END                                 AS price_category
FROM olist.order_items;

-- Add values of two columns row by row
SELECT
    order_id,
    product_id,
    price,
    freight_value,
    price + freight_value AS total_volume -- you can simply sum two columns
FROM olist.order_items;

/*
---------
-- Column transformations
--
-- Clauses:
-- SELECT DISTINCT
-- GROUP BY
---------
*/

SELECT *
FROM olist.order_items
LIMIT 1000;


-- deduplicating using SELECT DISTINCT
SELECT
    seller_id
FROM olist.order_items
WHERE DATE(shipping_limit_date) = DATE('2017-05-17');

SELECT DISTINCT
    seller_id
FROM olist.order_items
WHERE DATE(shipping_limit_date) = DATE('2017-05-17');

SELECT DISTINCT
    seller_id,
    product_id
FROM olist.order_items
WHERE DATE(shipping_limit_date) = DATE('2017-05-17');

-- equivalent: You can use a GROUP BY on the only column you are selecting to deduplicate as well
SELECT
    seller_id
FROM olist.order_items
WHERE DATE(shipping_limit_date) = DATE('2017-05-17')
GROUP BY seller_id;

/*
---------
-- Aggregate function
--
-- Clauses:
-- COUNT()
-- SUM()
-- AVG()
-- ...
 */

-- Using aggregate function on the entire table (without GROUP BYs), always return one row only
SELECT
    COUNT(*)                    AS no_of_rows,
    COUNT(DISTINCT seller_id)   AS unique_sellers,
    COUNT(DISTINCT product_id)  AS unique_products,
    COUNT(product_id)           AS products,
    COUNT(seller_id)            AS sellers,
    COUNT(1)                    AS ones,
    COUNT(0)                    AS zeroes,
    SUM(1)                      AS row_count,
    AVG(price)                  AS mean_price,
    MAX(price)                  AS max_price,
    MIN(price)                  AS min_price
FROM olist.order_items
WHERE DATE(shipping_limit_date) = DATE('2017-05-17');

/*
---------
-- Aggregate function with partitions (GROUP BY)
--
-- Clauses:
-- GROUP BY
-- COUNT()
-- SUM()
-- AVG()
-- ...
 */

SELECT *
FROM olist.order_items
LIMIT 1000;

-- number of order_items for each unique shipping_limit_date as a DATE
SELECT
    DATE(shipping_limit_date)   AS date_id,
    COUNT(*)                    AS order_items
FROM olist.order_items
GROUP BY DATE(shipping_limit_date)
ORDER BY DATE(shipping_limit_date)
LIMIT 1000;


SELECT
    DATE(shipping_limit_date)   AS date_id,
    COUNT(*)                    AS order_items
FROM olist.order_items
GROUP BY DATE(shipping_limit_date)
ORDER BY COUNT(*) DESC
LIMIT 1000;

SELECT
    DATE(shipping_limit_date)   AS date_id,
    COUNT(*)                    AS order_items
FROM olist.order_items
GROUP BY date_id        -- you can refer to the aliases specified in the SELECT clause for GROUP BY or ORDER BY
ORDER BY order_items
LIMIT 1000;

/*
---------
-- Putting them together
 */

--- top 10 sellers by revenue

/*
| seller_id | no_of_items | total_revenue |
|-----------|-------------|---------------|
| xyz       | 2353        | 124135036     |
| xyk       | 4424        | 122455364     |
| ...

 */

SELECT
    seller_id,
    COUNT(1)    AS no_of_items,
    SUM(price)  AS total_revenue
FROM olist.order_items
GROUP BY seller_id
ORDER BY total_revenue DESC
LIMIT 10;

-- top 10 products by quantity
SELECT
    product_id,
    COUNT(*)    AS quantity
FROM olist.order_items #<-- table name
GROUP BY product_id
ORDER BY quantity DESC
LIMIT 10;

-- for each day, how many items did each seller sell?
/*
| date_id | seller_id | no_of_items |
|---------|-----------|-------------|
| 2018-01-01 | xyz        | 124135036     |
| 2018-01-02 | xyz        | 122455364     |
| ...

 */

SELECT
    DATE(shipping_limit_date)   AS date_id,
    seller_id,
    COUNT(*)                    AS items_sold
FROM olist.order_items
GROUP BY
    DATE(shipping_limit_date),
    seller_id
ORDER BY
    seller_id,
    date_id;

-- adding sum of price
SELECT
    DATE(shipping_limit_date)   AS date_id,
    seller_id,
    COUNT(*)                    AS items_sold,
    SUM(price)                  AS revenue
FROM olist.order_items
GROUP BY
    DATE(shipping_limit_date),
    seller_id
ORDER BY
    seller_id,
    date_id;

-- items sold for each seller
SELECT
    seller_id,
    COUNT(1)    AS no_of_items
FROM olist.order_items
GROUP BY seller_id
LIMIT 10;


SELECT
    seller_id,
    COUNT(seller_id)            AS no_of_items,
    COUNT(DISTINCT seller_id)   AS unique_sellers
FROM olist.order_items
GROUP BY seller_id
LIMIT 10;
