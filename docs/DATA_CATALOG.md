# Data Catalog

## gold.dim_customers
Purpose:
Stores customer information enriched with geographic data.

Key Columns:
- customer_key (PK)
- customer_id
- customer_unique_id
- geolocation_key (FK)
- customer_city
- customer_state

---

## gold.dim_products
Purpose:
Stores product master information.

Key Columns:
- product_key (PK)
- product_id
- product_category_name
- product_weight_g
- product_volume_cm3
- product_size_category
- product_weight_category

---

## gold.dim_sellers
Purpose:
Stores seller information.

Key Columns:
- seller_key (PK)
- seller_id
- geolocation_key (FK)
- seller_city
- seller_state

---

## gold.dim_geolocation
Purpose:
Stores geographic reference information.

Key Columns:
- geolocation_key (PK)
- geolocation_zip_code_prefix
- geolocation_city
- geolocation_state
- geolocation_lat
- geolocation_lng

---

## gold.fact_orders_header
Purpose:
Stores one record per order.

Key Columns:
- order_id
- customer_key (FK)
- order_status
- order_purchase_timestamp
- order_delivered_customer_date

---

## gold.fact_order_items
Purpose:
Stores one record per product purchased.

Key Columns:
- order_id
- order_item_id
- product_key (FK)
- seller_key (FK)
- customer_key (FK)
- price
- freight_value

---

## gold.fact_order_payments
Purpose:
Stores payment details.

Key Columns:
- order_id
- customer_key (FK)
- payment_type
- payment_installments
- payment_value

---

## gold.fact_order_reviews
Purpose:
Stores customer review information.

Key Columns:
- review_id
- order_id
- customer_key (FK)
- review_score
- review_creation_date
