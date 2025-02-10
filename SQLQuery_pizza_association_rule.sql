-- Association Rule Mining Analysis in SQL Project 


--  Inspect the dataset before analysis
SELECT * FROM pizza_data;

-- Q1: Finding the Number of Product Pairs in Each Order
/* Purpose: This query calculates the number of unique product pairs that can be formed from each sales order.

To do that, we can  use a self-join to pair each product with every other product in the same order, then count the distinct pairs
*/
SELECT 
    o1.order_id,
    COUNT(DISTINCT 
        CASE 
            WHEN o1.pizza_id < o2.pizza_id THEN CONCAT(o1.pizza_id, '-', o2.pizza_id)
            ELSE CONCAT(o2.pizza_id, '-', o1.pizza_id)
        END
    ) AS unique_product_pairs
FROM 
    pizza_data o1
JOIN 
    pizza_data o2
ON 
    o1.order_id = o2.order_id
AND 
    o1.pizza_id <> o2.pizza_id
GROUP BY 
    o1.order_id
ORDER BY 
    o1.order_id;

-- Q2: Counting Orders for Each Product Pair
/*
Purpose: This query counts how many orders contain each unique pair of products.

To do this, we can use a similar self-join approach but focus on counting distinct orders for each product pair.
*/
SELECT 
    product_pair,
    COUNT(DISTINCT order_id) AS order_count
FROM (
    SELECT 
        o1.order_id,
        CASE 
            WHEN o1.pizza_id < o2.pizza_id THEN CONCAT(o1.pizza_id, '-', o2.pizza_id)
            ELSE CONCAT(o2.pizza_id, '-', o1.pizza_id)
        END AS product_pair
    FROM 
        pizza_data o1
    JOIN 
        pizza_data o2
    ON 
        o1.order_id = o2.order_id
    AND 
        o1.pizza_id < o2.pizza_id
) AS paired_orders
GROUP BY 
    product_pair
ORDER BY 
    order_count DESC;

-- Q3: Counting Orders for Product Pairs with Filters
/*
Purpose: This query counts orders for each product pair, but only considers orders with 2 to 10 distinct items.

To count orders for each product pair while filtering for orders that contain between 2 and 10 distinct items, we can use query first identifies orders with the required number of distinct items, then counts the product pairs within those orders.
*/

WITH OrderItemCounts AS (
    SELECT 
        order_id,
        COUNT(DISTINCT pizza_id) AS distinct_item_count
    FROM 
        pizza_data
    GROUP BY 
        order_id
    HAVING 
        COUNT(DISTINCT pizza_id) BETWEEN 2 AND 10
),
PairedOrders AS (
    SELECT 
        o1.order_id,
        CASE 
            WHEN o1.pizza_id < o2.pizza_id THEN CONCAT(o1.pizza_id, '-', o2.pizza_id)
            ELSE CONCAT(o2.pizza_id, '-', o1.pizza_id)
        END AS product_pair
    FROM 
        pizza_data o1
    JOIN 
        pizza_data o2
    ON 
        o1.order_id = o2.order_id
    AND 
        o1.pizza_id < o2.pizza_id
    JOIN 
        OrderItemCounts oic
    ON 
        o1.order_id = oic.order_id
)
SELECT 
    product_pair,
    COUNT(DISTINCT order_id) AS order_count
FROM 
    PairedOrders
GROUP BY 
    product_pair
ORDER BY 
    order_count DESC;

-- Q4: Top 10 Product Pairs
/*
Purpose: Retrieves the top 10 most common product pairs in orders with 2 to 10 distinct items.
*/

WITH OrderItemCounts AS (
    SELECT 
        order_id,
        COUNT(DISTINCT pizza_id) AS distinct_item_count
    FROM 
        pizza_data
    GROUP BY 
        order_id
    HAVING 
        COUNT(DISTINCT pizza_id) BETWEEN 2 AND 10
),
PairedOrders AS (
    SELECT 
        o1.order_id,
        CASE 
            WHEN o1.pizza_id < o2.pizza_id THEN CONCAT(o1.pizza_id, '-', o2.pizza_id)
            ELSE CONCAT(o2.pizza_id, '-', o1.pizza_id)
        END AS product_pair
    FROM 
        pizza_data o1
    JOIN 
        pizza_data o2
    ON 
        o1.order_id = o2.order_id
    AND 
        o1.pizza_id < o2.pizza_id
    JOIN 
        OrderItemCounts oic
    ON 
        o1.order_id = oic.order_id
)
SELECT TOP 10
    product_pair,
    COUNT(DISTINCT order_id) AS order_count
FROM 
    PairedOrders
GROUP BY 
    product_pair
ORDER BY 
    order_count DESC;

-- Q5: Finding Commonly Purchased Subcategories
/*
Purpose: Identifies commonly purchased subcategories in the same orders.

To identify commonly purchased subcategories in the same orders, we can 
follow a similar approach to the product pair analysis but focus on category 
instead of pizza_id
*/
WITH categoryPairs AS (
    SELECT 
        o1.order_id,
        CASE 
            WHEN o1.category < o2.category THEN CONCAT(o1.category, '-', o2.category)
            ELSE CONCAT(o2.category, '-', o1.category)
        END AS category_pair
    FROM 
        pizza_data o1
    JOIN 
        pizza_data o2
    ON 
        o1.order_id = o2.order_id
    AND 
        o1.category < o2.category
)
SELECT 
    category_pair,
    COUNT(DISTINCT order_id) AS order_count
FROM 
    categoryPairs
GROUP BY 
    category_pair
ORDER BY 
    order_count DESC;


-- Q6: Calculates the total number of orders, the number of orders containing Product 1 (lhs), Product 2 (rhs), and both Query to calculate total number of orders, and orders containing Product 1, Product 2, and both Query to calculate orders with multiple products and specific product pairs
/* 
we are considering all possible pairs of products within the same order, calculating the number of orders that contain each unique pair of products. In the query, Product 1 and Product 2 refer to any two distinct pizza products that appear together in the same order.
*/

WITH OrderItemCounts AS (
    SELECT 
        order_id,
        COUNT(DISTINCT pizza_id) AS distinct_item_count
    FROM 
        pizza_data
    GROUP BY 
        order_id
),
PairedOrders AS (
    SELECT 
        o1.order_id,
        o1.pizza_id AS product1,
        o2.pizza_id AS product2
    FROM 
        pizza_data o1
    JOIN 
        pizza_data o2
    ON 
        o1.order_id = o2.order_id
    AND 
        o1.pizza_id < o2.pizza_id -- Ensure each pair is counted once
),
ProductPairsCount AS (
    SELECT 
        product1,
        product2,
        COUNT(DISTINCT order_id) AS pair_order_count
    FROM 
        PairedOrders
    GROUP BY 
        product1, product2
)
SELECT 
    (SELECT COUNT(DISTINCT order_id) FROM pizza_data) AS total_orders,
    product1,
    product2,
    pair_order_count
FROM 
    ProductPairsCount
ORDER BY 
    pair_order_count DESC;

-- Q7: Calculating Support, Confidence, and Lift
/*
Purpose: Computes support, confidence, and lift for the association rule between Product 1 and Product 2
Explanation:
Support: The proportion of orders containing both products.
Confidence: The likelihood that Product 2 is purchased when Product 1 is purchased.
Lift: The ratio of the observed support to the expected support if the products were independent.
*/

WITH OrderItemCounts AS (
    SELECT 
        order_id,
        COUNT(DISTINCT pizza_id) AS distinct_item_count
    FROM 
        pizza_data
    GROUP BY 
        order_id
),
PairedOrders AS (
    SELECT 
        o1.order_id,
        o1.pizza_id AS product1,
        o2.pizza_id AS product2
    FROM 
        pizza_data o1
    JOIN 
        pizza_data o2
    ON 
        o1.order_id = o2.order_id
    AND 
        o1.pizza_id < o2.pizza_id -- Ensure each pair is counted once
),
ProductPairsCount AS (
    SELECT 
        product1,
        product2,
        COUNT(DISTINCT order_id) AS pair_order_count
    FROM 
        PairedOrders
    GROUP BY 
        product1, product2
),
OrderCounts AS (
    SELECT COUNT(DISTINCT order_id) AS total_orders
    FROM pizza_data
)
SELECT 
    pp.product1,
    pp.product2,
    -- Calculate support: Proportion of orders containing both products
    (pp.pair_order_count * 1.0) / oc.total_orders AS support,
    -- Calculate confidence: Probability that product2 is purchased when product1 is purchased
    (pp.pair_order_count * 1.0) / (SELECT COUNT(DISTINCT order_id) FROM pizza_data WHERE pizza_id = pp.product1) AS confidence,
    -- Calculate lift: Observed support / Expected support if independent
    (pp.pair_order_count * 1.0) / oc.total_orders / 
        ((SELECT COUNT(DISTINCT order_id) FROM pizza_data WHERE pizza_id = pp.product1) * 1.0) / oc.total_orders / 
        ((SELECT COUNT(DISTINCT order_id) FROM pizza_data WHERE pizza_id = pp.product2) * 1.0) / oc.total_orders AS lift
FROM 
    ProductPairsCount pp, OrderCounts oc
ORDER BY 
    support DESC, lift DESC;



-- Q8: Filter out significant association rules that provide actionable insights

WITH OrderCounts AS (
    SELECT COUNT(DISTINCT order_id) AS total_orders
    FROM pizza_data
),
ProductPairsCount AS (
    SELECT 
        o1.pizza_id AS product1,
        o2.pizza_id AS product2,
        COUNT(DISTINCT o1.order_id) AS pair_order_count
    FROM 
        pizza_data o1
    JOIN 
        pizza_data o2
    ON 
        o1.order_id = o2.order_id
    AND 
        o1.pizza_id < o2.pizza_id -- Ensures each pair is counted once
    GROUP BY 
        o1.pizza_id, o2.pizza_id
),
SupportConfidenceLift AS (
    SELECT 
        pp.product1,
        pp.product2,
        pp.pair_order_count,
        oc.total_orders,
        -- Calculate support: Proportion of orders containing both products
        (pp.pair_order_count * 1.0) / oc.total_orders AS support,
        -- Calculate confidence: Probability that product2 is purchased when product1 is purchased
        (pp.pair_order_count * 1.0) / 
        (SELECT COUNT(DISTINCT order_id) FROM pizza_data WHERE pizza_id = pp.product1) AS confidence,
        -- Calculate lift: Observed support / Expected support if independent
        (pp.pair_order_count * 1.0) / oc.total_orders / 
        ((SELECT COUNT(DISTINCT order_id) FROM pizza_data WHERE pizza_id = pp.product1) * 1.0) / oc.total_orders / 
        ((SELECT COUNT(DISTINCT order_id) FROM pizza_data WHERE pizza_id = pp.product2) * 1.0) / oc.total_orders AS lift
    FROM 
        ProductPairsCount pp, OrderCounts oc
)
SELECT 
    product1,
    product2,
    support,
    confidence,
    lift
FROM 
    SupportConfidenceLift
WHERE
    -- Optional filters for significant insights
    support >= 0.05  -- Example threshold for support
    AND confidence >= 0.3  -- Example threshold for confidence
    AND lift > 1  -- Example threshold for lift
ORDER BY 
    support DESC;

