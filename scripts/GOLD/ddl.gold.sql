/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================

Script Purpose:
    This script creates business-ready views in the Gold layer
    of the Olist Data Warehouse.

    The Gold layer represents the presentation layer following
    a Star Schema design.

    It consists of:
        • Dimension Views
        • Fact Views

    These views transform and enrich the Silver layer into
    analytics-ready datasets for reporting, dashboards and
    business intelligence.

Usage:
    Execute this script after successfully loading the Silver layer.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_geolocation
-- =============================================================================

IF OBJECT_ID('gold.dim_geolocation', 'V') IS NOT NULL
    DROP VIEW gold.dim_geolocation;
GO

CREATE VIEW gold.dim_geolocation AS

SELECT
    DENSE_RANK() OVER(
        ORDER BY
            geolocation_zip_code_prefix,
            geolocation_city,
            geolocation_state,
            geolocation_lat,
            geolocation_lng
    ) AS geolocation_key,

    geolocation_zip_code_prefix,
    geolocation_city,
    geolocation_state,
    geolocation_lat,
    geolocation_lng

FROM silver.olist_geolocation_dataset;
GO

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================

IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

  CREATE VIEW gold.dim_customers AS(
   select 
   row_number() over(order by c.customer_city,c.customer_state,c.customer_id)  customer_key,
   c.customer_id,
   c.customer_unique_id,
   g.geolocation_key,
   c.customer_city,
   c.customer_state
   from silver.olist_customers_dataset c
   left join gold.dim_geolocation g
   on c.customer_zip_code_prefix = g.geolocation_zip_code_prefix)

GO


-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================

IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
(
 select 
 product_key,
 product_id,
 product_category_name,
 product_photos_qty,
 product_weight_g,
 product_volume_cm,
   case   when  product_volume_cm  <= 1000 then 'small'
 when product_volume_cm  < 10000 then 'medium'
  when product_volume_cm >= 10000 then 'big' 
  else 'n/a' end  product_size_range
 from (
 SELECT 
 RANK() OVER(ORDER BY PRODUCT_ID) product_key,
 product_id,
 product_category_name,
 product_photos_qty, product_weight_g,product_length_cm ,
 product_height_cm,product_width_cm,
cast( product_length_cm as int)  * cast(product_height_cm as int) * cast(product_width_cm as int) product_volume_cm)


GO


-- =============================================================================
-- Create Dimension: gold.dim_sellers
-- =============================================================================

IF OBJECT_ID('gold.dim_sellers', 'V') IS NOT NULL
    DROP VIEW gold.dim_sellers;
GO

CREATE VIEW gold.dim_sellers AS(
     select 
     row_number() over (order by s.seller_id) seller_key,
     g.geolocation_key,
     s.seller_id,
     s.seller_city,
     s.seller_state
     from silver.olist_sellers_dataset s
     left join gold.dim_geolocation g
     on s.seller_zip_code_prefix = g.geolocation_zip_code_prefix)

GO


-- =============================================================================
-- Create Fact: gold.fact_orders_header
-- =============================================================================

IF OBJECT_ID('gold.fact_orders_header', 'V') IS NOT NULL
    DROP VIEW gold.fact_orders_header;
GO


CREATE VIEW gold.fact_orders_header AS

SELECT

    o.order_id,
    dc.customer_key,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date

FROM silver.olist_orders_dataset o

LEFT JOIN gold.dim_customers dc
ON o.customer_id = dc.customer_id;
GO

-- =============================================================================
-- Create Fact: gold.fact_order_items
-- =============================================================================

IF OBJECT_ID('gold.fact_order_items', 'V') IS NOT NULL
    DROP VIEW gold.fact_order_items;
GO

 
     CREATE VIEW gold.fact_order_items AS (
      select 
        oi.order_id,
        oi.order_item_id,
       
        gp.product_key,
        gs.seller_key,
        foh.customer_key,
 
        oi.shipping_limit_date,
       
      
        oi.price,
        oi.freight_value

        from silver.olist_order_items_dataset oi
        left join gold.dim_products gp
        on oi.product_id = gp.product_id
        left join gold.dim_sellers gs
        on oi.seller_id = gs.seller_id
        left join  gold.fact_orders_header foh
        on oi.order_id = foh.order_id
        )
GO


-- =============================================================================
-- Create Fact: gold.fact_order_payments
-- =============================================================================

IF OBJECT_ID('gold.fact_order_payments', 'V') IS NOT NULL
    DROP VIEW gold.fact_order_payments;
GO

CREATE VIEW gold.fact_order_payments AS

SELECT

    op.order_id,
    boc.customer_key,
    op.payment_sequential,
    op.payment_type,
    op.payment_installments,
    op.payment_value

FROM silver.olist_order_payments_dataset op

LEFT JOIN silver.bridge_order_customer boc
ON op.order_id = boc.order_id;
GO

-- =============================================================================
-- Create Fact: gold.fact_order_reviews
-- =============================================================================

IF OBJECT_ID('gold.fact_order_reviews', 'V') IS NOT NULL
    DROP VIEW gold.fact_order_reviews;
GO

CREATE VIEW gold.fact_order_reviews AS

SELECT

    r.review_id,
    r.order_id,
    boc.customer_key,
    r.review_score,
    r.review_creation_date,
    r.review_answer_timestamp

FROM silver.olist_order_reviews_dataset r

LEFT JOIN silver.bridge_order_customer boc
ON r.order_id = boc.order_id;
GO
