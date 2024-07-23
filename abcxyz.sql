WITH product_sales AS (
    SELECT
        dr_ndrugs AS product,
        SUM(dr_kol) AS amount,
        SUM(dr_kol * (dr_croz - dr_czak) - dr_sdisc) AS profit,
        SUM(dr_kol * dr_croz - dr_sdisc) AS revenue
    FROM sales
    GROUP BY dr_ndrugs
),
main_query AS (
    SELECT
        product,
        CASE 
            WHEN SUM(amount) OVER(ORDER BY amount DESC) / SUM(amount) OVER() <= 0.8 THEN 'A'
            WHEN SUM(amount) OVER(ORDER BY amount DESC) / SUM(amount) OVER() <= 0.95 THEN 'B'
            ELSE 'C'
        END AS amount_abc,
        CASE 
            WHEN SUM(profit) OVER(ORDER BY profit DESC) / SUM(profit) OVER() <= 0.8 THEN 'A'
            WHEN SUM(profit) OVER(ORDER BY profit DESC) / SUM(profit) OVER() <= 0.95 THEN 'B'
            ELSE 'C'
        END AS profit_abc,
        CASE 
            WHEN SUM(revenue) OVER(ORDER BY revenue DESC) / SUM(revenue) OVER() <= 0.8 THEN 'A'
            WHEN SUM(revenue) OVER(ORDER BY revenue DESC) / SUM(revenue) OVER() <= 0.95 THEN 'B'
            ELSE 'C'
        END AS revenue_abc
    FROM product_sales
),
xyz_sales AS (
    SELECT 
        dr_ndrugs AS product,
        TO_CHAR(dr_dat,'YYYY-WW') AS ym,
        SUM(dr_kol) AS sales
    FROM sales 
    GROUP BY product, ym
),
xyz_analysis AS (
    SELECT
        product,
        CASE
            WHEN STDDEV_SAMP(sales)/AVG(sales) >= 0.25 THEN 'Z'
            WHEN STDDEV_SAMP(sales)/AVG(sales) >= 0.1 THEN 'Y'
            ELSE 'X'
        END AS xyz_sales
    FROM xyz_sales
    GROUP BY product
    HAVING COUNT(DISTINCT ym) >= 4
)
SELECT 
    mq.product, 
    mq.amount_abc,
    mq.profit_abc,
    mq.revenue_abc,
    xyz.xyz_sales
FROM main_query mq
LEFT JOIN xyz_analysis xyz
ON mq.product = xyz.product
WHERE 1=1
  [[AND mq.product = {{product}}]]
  [[AND mq.amount_abc = {{amount_abc}}]]
  [[AND mq.profit_abc = {{profit_abc}}]]
  [[AND mq.revenue_abc = {{revenue_abc}}]]
  [[AND xyz.xyz_sales = {{xyz_sales}}]] 
ORDER BY mq.product;
