CREATE TABLE suppliers (
    supplier_id       VARCHAR(10)    PRIMARY KEY,
    supplier_name     VARCHAR(100)   NOT NULL,
    contact_person    VARCHAR(80),
    email             VARCHAR(120),
    phone             VARCHAR(15)    NOT NULL,
    city              VARCHAR(50),
    state             VARCHAR(50),
    pincode           VARCHAR(10),
    category          VARCHAR(50),
    gstin             VARCHAR(20),
    payment_terms_days INT,
    rating            DECIMAL(3,1),
    created_date      DATE,
    is_active         INT DEFAULT 1
);

CREATE TABLE products (
    product_id        VARCHAR(10)    PRIMARY KEY,
    product_name      VARCHAR(150)   NOT NULL,
    category          VARCHAR(50)    NOT NULL,
    subcategory       VARCHAR(80),
    brand             VARCHAR(80),
    sku               VARCHAR(30)    UNIQUE,
    mrp               DECIMAL(10,2)  NOT NULL,
    selling_price     DECIMAL(10,2)  NOT NULL,
    cost_price        DECIMAL(10,2),
    gst_rate          INT            DEFAULT 18,
    hsn_code          VARCHAR(10),
    weight_grams      INT,
    supplier_id       VARCHAR(10),
    rating            DECIMAL(3,1),
    review_count      INT            DEFAULT 0,
    is_active         INT     DEFAULT 1,
    launch_date       DATE,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
);

CREATE TABLE inventory (
    inventory_id          VARCHAR(10)  PRIMARY KEY,
    product_id            VARCHAR(10)  NOT NULL,
    warehouse_location    VARCHAR(50),
    quantity_available    INT          DEFAULT 0,
    quantity_reserved     INT          DEFAULT 0,
    reorder_level         INT,
    reorder_quantity      INT,
    last_restocked_date   DATE,
    unit_cost             DECIMAL(10,2),
    total_inventory_value DECIMAL(12,2),
    status                VARCHAR(20),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE customers (
    customer_id        VARCHAR(12)   PRIMARY KEY,
    first_name         VARCHAR(50)   NOT NULL,
    last_name          VARCHAR(50)   NOT NULL,
    email              VARCHAR(120)  UNIQUE,
    phone              VARCHAR(15),
    city               VARCHAR(50),
    state              VARCHAR(50),
    pincode            VARCHAR(10),
    gender             VARCHAR(10),
    age                INT,
    segment            VARCHAR(20),
    registration_date  DATE,
    last_login_date    DATE,
    total_orders       INT           DEFAULT 0,
    total_spent        DECIMAL(12,2) DEFAULT 0.00,
    is_verified        INT    DEFAULT 0,
    is_active          INT    DEFAULT 1 
);

create INDEX idx_segment on customers(segment);
create INDEX idx_city on customers(city);
create INDEX idx_state on customers(state);

CREATE TABLE orders (
    order_id           VARCHAR(12)   PRIMARY KEY,
    customer_id        VARCHAR(12)   NOT NULL,
    order_date         DATE          NOT NULL,
    order_time         TIME,
    status             VARCHAR(20)   NOT NULL,
    city               VARCHAR(50),
    state              VARCHAR(50),
    pincode            VARCHAR(10),
    total_amount       DECIMAL(12,2),
    gst_amount         DECIMAL(10,2),
    shipping_charge    DECIMAL(8,2)  DEFAULT 0,
    discount_amount    DECIMAL(10,2) DEFAULT 0,
    final_amount       DECIMAL(12,2) NOT NULL,
    payment_method     VARCHAR(30),
    shipping_partner   VARCHAR(50),
    tracking_id        VARCHAR(30),
    delivered_date     DATE,
    is_cod             INT DEFAULT 0,
    channel            VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
create INDEX idx_order_date on orders(order_date);
create INDEX idx_status on orders(status);
create INDEX idx_customer on orders(customer_id);
create INDEX idx_states on orders(state);

CREATE TABLE order_items (
    item_id            VARCHAR(12)   PRIMARY KEY,
    order_id           VARCHAR(12)   NOT NULL,
    product_id         VARCHAR(10)   NOT NULL,
    product_name       VARCHAR(150),
    category           VARCHAR(50),
    quantity           INT           NOT NULL DEFAULT 1,
    unit_price         DECIMAL(10,2) NOT NULL,
    gst_rate           INT,
    gst_amount         DECIMAL(10,2),
    discount_amount    DECIMAL(10,2) DEFAULT 0,
    total_price        DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
create INDEX idx_order_id on order_items(order_id);
create INDEX idx_product_id on order_items(product_id);
create INDEX idx_category  on order_items(category);

CREATE TABLE payments (
    payment_id         VARCHAR(12)   PRIMARY KEY,
    order_id           VARCHAR(12)   NOT NULL,
    customer_id        VARCHAR(12)   NOT NULL,
    payment_date       DATE          NOT NULL,
    payment_time       TIME,
    payment_method     VARCHAR(30),
    amount             DECIMAL(12,2) NOT NULL,
    status             VARCHAR(20),
    transaction_id     VARCHAR(30)   UNIQUE,
    bank_name          VARCHAR(60),
    gateway            VARCHAR(40),
    refund_amount      DECIMAL(10,2) DEFAULT 0,
    refund_date        DATE,
    FOREIGN KEY (order_id)    REFERENCES orders(order_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
create INDEX idx_payment_date on payments(payment_date);
create INDEX idx_status_ on payments(status);
create INDEX idx_gateway on payments(gateway);


CREATE TABLE returns (
    return_id          VARCHAR(10)   PRIMARY KEY,
    order_id           VARCHAR(12)   NOT NULL,
    customer_id        VARCHAR(12)   NOT NULL,
    return_date        DATE          NOT NULL,
    reason             VARCHAR(100),
    return_amount      DECIMAL(12,2),
    refund_status      VARCHAR(20),
    refund_date        DATE,
    return_condition   VARCHAR(20),
    remarks            TEXT,
    FOREIGN KEY (order_id)    REFERENCES orders(order_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
create INDEX idx_return_date on returns(return_date);
create INDEX idx_refund_status on returns(refund_status);


--1. Gross Merchandise Value (GMV) --
select 
	round(sum(final_amount), 2) as gmv
	from orders;

--2. Net Revenue --
select
	round(sum(final_amount), 2) as net_revenue
	from orders where status='Delivered';

--3. Average Order Value(AOV) --
select 
	round((sum(case when status='Delivered' then final_amount end))/
	(count(case when status='Delivered' then 1 end)),2)
	as avg_order_value from orders;

--4. Cancellation Rate --
select
	round((count(case when status='Cancelled' then 1 end))::numeric /(count(order_id)) * 100, 2)
	as cancellation_rate from orders;

--5. Return Rate --
select
	round((count(case when status='Returned' then 1 end))::numeric / 
	(count(case when status='Delivered' then 1 end)) * 100, 2)
	as return_rate from orders;

--6. Customer Lifetime Value --
select segment,
	round(avg(total_spent), 2) as avg_spent
	from customers group by segment;

--7. Month-over-Month Growth --
with monthly_revenue as (
	select
		extract(year from order_date) as year,
		extract(month from order_date) as month,
		sum(final_amount) as current_month_revenue
	from orders group by extract(year from order_date),
	extract(month from order_date)
),
revenue_with_previous as(
	select year, month, current_month_revenue,
	lag(current_month_revenue)
over (order by year, month) as previous_month_revenue
from monthly_revenue
)
select year, month, current_month_revenue, previous_month_revenue,
	round(((current_month_revenue - previous_month_revenue)/ 
	nullif(previous_month_revenue, 0)) * 100,2) as mon_growth_percent
	from revenue_with_previous order by year, month;
	
--8. Top Category Revenue Share --
select category,
	round((sum(total_price)*100) / sum(sum(total_price)) over(), 2)
	as revenue_percent
	from order_items group by category order by revenue_percent desc;

--9. Payment Failure Rate --
select
	round((count(case when status='Failed' then 1 end)::numeric / count(status)) *100, 2)
	as failed_rate from payments;

--10. Inventory Fill Rate --
select
	round((count(case when status='In Stock' then 1 end)::numeric / count(status))*100, 2)
	as inventory_fill_rate from inventory;

-- COHORT ANALYSIS--
with cohort as
(select extract(year from c.registration_date) as cohort_year,
	extract(month from c.registration_date) as cohort_month,
	((extract(year from o.order_date) - extract(year from c.registration_date)) * 12 +
	(extract(month from o.order_date) - extract(month from c.registration_date))) + 1
	as order_month from customers c join orders o 
	on c.customer_id=o.customer_id
)	
select cohort_year, cohort_month,
	count(case when order_month = 1 then 1 end) as month_1,
	count(case when order_month = 2 then 1 end) as month_2,
	count(case when order_month = 3 then 1 end) as month_3
	from cohort group by cohort_year, cohort_month
	order by cohort_year, cohort_month;
