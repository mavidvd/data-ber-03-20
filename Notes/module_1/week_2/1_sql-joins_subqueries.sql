USE olist;
/*
---------
-- Joins
--
-- Clauses:
-- FROM
--  (INNER|LEFT) JOIN
--  ON
---------
*/

-- Manually: Get the english product_category of the most expensive item sold

-- 1. get the product_id of the most expensive item sold
SELECT
    product_id,
    price
FROM order_items
ORDER BY price DESC
LIMIT 1;
-- product_id is 489ae2aa008f021502940f251d4cce7f

-- 2. get the portuguese product_category of that product_id
SELECT
    product_id,
    product_category_name AS portuguese_product_category_name
FROM products
WHERE product_id = '489ae2aa008f021502940f251d4cce7f';
-- portuguese product_category is utilidades_domesticas

-- 3. get the english translation
SELECT
    product_category_name,
    product_category_name_english
FROM product_category_name_translation
WHERE product_category_name = 'utilidades_domesticas';

--
-- Doing it all at once using INNER JOINs:
--
SELECT
    oi.product_id,
    oi.price,
    p.product_category_name             AS product_category_name_portuguese,
    pcnt.product_category_name_english
FROM order_items oi
    INNER JOIN products p
    ON oi.product_id = p.product_id
    INNER JOIN product_category_name_translation pcnt
    ON p.product_category_name = pcnt.product_category_name
ORDER BY oi.price DESC
LIMIT 1;

-- we don't need all the columns
SELECT
    pcnt.product_category_name_english,
    oi.price
FROM order_items oi
    INNER JOIN products p
    ON oi.product_id = p.product_id
    INNER JOIN product_category_name_translation pcnt
    ON p.product_category_name = pcnt.product_category_name
ORDER BY oi.price DESC
LIMIT 1;


--
-- For each product_category (english), get the number of items sold, the total revenue and the revenue per item sold
--
/*
| product_category | items_sold | total_revenue | revenue_per_item_sold |
|------------------|------------|---------------|-----------------------|
| toiletries       | 543        | 125236.34     | 125236.34 / 543       |
| ...
*/

-- 1. get items_sold & total_revenue for each unique product_id
SELECT
    oi.product_id,
    COUNT(*)        AS items_sold,
    SUM(oi.price)   AS total_revenue
FROM order_items oi
GROUP BY oi.product_id;

-- 2. for each unique product_id, get the product_category_portuguese
SELECT
    p.product_category_name AS product_category_name_portuguese,
    COUNT(*)        AS items_sold,
    SUM(oi.price)   AS total_revenue
FROM order_items oi
    INNER JOIN products p
    ON oi.product_id = p.product_id
GROUP BY
    product_category_name_portuguese;

-- 3. translate product_category_name_portuguese to english
SELECT
    COALESCE(pcnt.product_category_name_english, 'uncategorized')   AS product_category_name_english,
    COUNT(*)                                                        AS items_sold,
    SUM(oi.price)                                                   AS total_revenue,
    SUM(oi.price) / COUNT(*)                                        AS revenue_per_item_sold
FROM order_items oi
    INNER JOIN products p
    ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation pcnt            -- IMPORTANT! You need a LEFT JOIN here as not all
                                                                -- products map to a product_category. Hence, the
                                                                -- COALESCE() in the SELECT clause
    ON p.product_category_name = pcnt.product_category_name
GROUP BY
    1
ORDER BY
    4 DESC;

--
-- Investigate missing product categories
--

-- 1. get a list of all portuguese product category names in the products table
WITH unique_products AS (
    SELECT DISTINCT
        product_category_name
    FROM products)

-- 2. compare them to the translation table
SELECT *
FROM unique_products up
    LEFT JOIN product_category_name_translation pcnt
    ON up.product_category_name = pcnt.product_category_name
WHERE pcnt.product_category_name IS NULL;

SELECT
    COUNT(*),
    COUNT(DISTINCT product_category_name)
FROM product_category_name_translation;


--
-- Average review rating, grouped by seller state
--
/*
| seller_state | avg_review | no_of_reviews |
|--------------|------------|---------------|
| SP           | 3.9        | 12495         |
| PA           | 3.3        | 5363          |
| ... | ... | ... |
 */

SELECT *
FROM sellers
LIMIT 1000;

-- are seller_ids unique in the sellers table?
SELECT
    COUNT(*),
    COUNT(DISTINCT seller_id)
FROM sellers;
-- yes

SELECT *
FROM order_items
ORDER BY order_id
LIMIT 1000;

-- get a unique list of seller_id <-> order_id relations
SELECT DISTINCT
    seller_id,
    order_id
FROM order_items;

-- Combine both datasets
-- 1. approach: nested subquery

SELECT
    s.seller_state,
    s.seller_id,
    so.order_id
FROM sellers s
    INNER JOIN (SELECT DISTINCT
                    seller_id,
                    order_id
                FROM order_items) so
    ON s.seller_id = so.seller_id
ORDER BY 1,2
LIMIT 1000;

-- 2. approach: create temporary table

CREATE TEMPORARY TABLE seller_order_links AS
    SELECT DISTINCT
        seller_id,
        order_id
    FROM order_items;

SELECT
    s.seller_state,
    s.seller_id,
    sol.order_id
FROM sellers s
    INNER JOIN seller_order_links sol
    ON s.seller_id = sol.seller_id
ORDER BY 1,2
LIMIT 1000;

-- 3. approach: Common Table Expressions (CTE) aka WITH tables

WITH seller_order_links2 AS (
    SELECT DISTINCT
        seller_id,
        order_id
    FROM order_items),

add_additional_tables AS (
    SELECT 1)                   -- no more comma means you are now entering the main query

SELECT
    s.seller_state,
    s.seller_id,
    sol.order_id
FROM sellers s
    INNER JOIN seller_order_links2 sol
    ON s.seller_id = sol.seller_id
ORDER BY 1,2;

-- get review score for each order
SELECT *
FROM order_reviews
LIMIT 100;

SELECT
    COUNT(*),
    COUNT(DISTINCT order_id)
FROM order_reviews;

-- check why those numbers don't match: there have to be some order_ids that have more than 1 review

-- 1. get a list of all order_ids and the number of reviews
SELECT
    order_id,
    COUNT(*)    AS no_of_reviews
FROM order_reviews
GROUP BY order_id
HAVING no_of_reviews > 1;

-- inspect a small sample
SELECT *
FROM order_reviews
WHERE order_id IN ('fd61441ba2a7b57e6342862e779b10b0', 'e433edc92cb5e3ae5515301b3309e303', 'df56136b8031ecd28e200bb18e6ddb2e')
ORDER BY order_id;

-- there are a few orders that have more than 1 rating. In that case, use the most recent
-- assumption: review_answer_timestamp, are unique for each order_id

-- check if order_id, review_answer_timestamp combinations are unique
SELECT
    COUNT(*),
    COUNT(DISTINCT CONCAT(order_id, review_answer_timestamp))
FROM order_reviews
LIMIT 100;

SELECT
    order_id,
    review_answer_timestamp,
    CONCAT(order_id, review_answer_timestamp)
FROM order_reviews;

-- get max review_answer_timestamp for each order_id
SELECT
    order_id,
    MAX(review_answer_timestamp) AS latest_review_timestamp
FROM order_reviews
GROUP BY order_id;

-- filter order_reviews with latest_review_timestamps by inner joining
WITH reviews_to_keep AS (
    SELECT
        order_id,
        MAX(review_answer_timestamp) AS latest_review_timestamp
    FROM order_reviews
    GROUP BY order_id),

latest_review_score AS (
    SELECT
        ore.order_id,
        ore.review_score
    FROM order_reviews ore
        INNER JOIN reviews_to_keep rtk
        ON ore.order_id = rtk.order_id
        AND ore.review_answer_timestamp = rtk.latest_review_timestamp),  -- for each order_id, the latest review rating

-- add previous pre-filter steps
seller_order_links AS (
    SELECT DISTINCT
        seller_id,
        order_id
    FROM order_items),

seller_orders_relations AS (
    SELECT
        s.seller_state,
        s.seller_id,
        sol.order_id
    FROM sellers s
        INNER JOIN seller_order_links sol
        ON s.seller_id = sol.seller_id)       -- for each seller, all order_ids they were associated with and their state

SELECT
    sor.seller_state,
    AVG(lrs.review_score)   AS avg_review_score,
    COUNT(1)                AS no_of_reviews
FROM seller_orders_relations sor
    INNER JOIN latest_review_score lrs
    ON sor.order_id = lrs.order_id
GROUP BY 1
ORDER BY 2 DESC;

--
-- Further examples:
--
-- Monthly revenue for each state in 2018
--
/*
| month_id | customer_state | revenue |
------------|------------|---------|
| 2018-01-01  | PA        | 12495   |
| 2018-02-01  | PA        | 5363    |
| ... | ... | ... |
 */

SELECT
    order_id,
    order_purchase_timestamp,
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m-01'),
    YEAR(order_purchase_timestamp)
FROM orders
LIMIT 100;

SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01') AS month_id,
    c.customer_state,
    SUM(oi.price)               AS revenue
FROM order_items oi
    INNER JOIN orders o
    ON oi.order_id = o.order_id
    INNER JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
    AND YEAR(o.order_purchase_timestamp) = 2018
GROUP BY month_id, c.customer_state
ORDER BY c.customer_state, month_id;

SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01') AS month_id,
    c.customer_state,
    SUM(oi.price)                                       AS revenue
FROM order_items oi
    INNER JOIN orders o
    ON oi.order_id = o.order_id
    INNER JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
   AND YEAR(o.order_purchase_timestamp) = 2018
GROUP BY month_id, c.customer_state
-- HAVING revenue > 1000
ORDER BY c.customer_state, month_id;

-- Additional challenge: Find the top 3 customer stats based on revenue for each month in 2018
