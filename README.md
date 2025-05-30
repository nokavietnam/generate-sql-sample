# generate-sql-sample

## Introduction

Have you ever found yourself in a situation where you've just read a article about optimizing SQL queries and wanted to try out the methods but you didn't have a large database to practice with? As developer, we often only work in development environments where the data is limited to a few hundred or thousand records. This mean we rarely get the chance to practice with millions of records. In this post, I'll share how to generate a dummy dataset with hundreds of millions of records so you can practice and test your optimization techniques.

## Generate dummy data postgresql

### Run docker create database Postgresql for test

```bash
cd databae && docker compose -f database/docker-compose-postgresql.yaml up -d
```

### Create sequence for id

```sql

-- Tạo sequence cho order_id
CREATE SEQUENCE payment_seq
    START WITH 21243721
    INCREMENT BY 1
    NO CYCLE;
```

### create table

```sql
-- Tạo bảng payments
CREATE TABLE payments (
    order_id BIGINT PRIMARY KEY,
    customer_id INT NOT NULL,
    payment_method VARCHAR(20) NOT NULL,
    amount_paid NUMERIC(10, 2) NOT NULL,
    transaction_date TIMESTAMP NOT NULL,
    status VARCHAR(10) NOT NULL CHECK (status IN ('completed', 'pending', 'failed'))
);
```

### create PROCEDURE

```sql
CREATE OR REPLACE PROCEDURE generate_payments(p_num_payments INT)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Chèn dữ liệu bằng generate_series
    INSERT INTO payments (order_id, customer_id, payment_method, amount_paid, transaction_date, status)
    SELECT
        nextval('payment_seq'),
        (RANDOM() * 9999 + 1)::INT,
        CASE
            WHEN RANDOM() < 0.5 THEN 'Credit Card'
            WHEN RANDOM() < 0.8 THEN 'PayPal'
            ELSE 'Bank Transfer'
        END,
        ROUND((RANDOM() * (500 - 10) + 10)::NUMERIC, 2),
        NOW() - INTERVAL '1 year' * RANDOM(),
        CASE
            WHEN RANDOM() < 0.9 THEN 'completed'
            WHEN RANDOM() < 0.95 THEN 'pending'
            ELSE 'failed'
        END
    FROM generate_series(1, p_num_payments);

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error: %', SQLERRM;
        ROLLBACK;
        RAISE;
END;
$$;
```

### generate dummy data

```sql
BEGIN;
CALL generate_payments(100000000);
COMMIT;
```

If your computer not enough RAM for script. You can run

```sql

-- Toi uu bo nho
DO $$
BEGIN
    FOR i IN 1..10 LOOP
        CALL generate_payments(1000000); -- 1 triệu mỗi lần
        COMMIT;
    END LOOP;
END $$;
```

## Test

```text

SELECT COUNT(*)
FROM payments
WHERE status = 'failed'
AND transaction_date > NOW() - INTERVAL '30 days';

```

Time Execution: 6 second

## How to reduce time query

### How to resolve

Solution:

- Create index to optimize query

- create partition

- parallel execution

### Sample

```sql
-- Optimize
-- Tạo chỉ mục để tối ưu truy vấn
CREATE INDEX idx_payments_customer_id ON payments (customer_id);
CREATE INDEX idx_payments_transaction_date ON payments (transaction_date);
CREATE INDEX idx_payments_status ON payments (status);

-- phân vùng bảng theo transaction_date
CREATE TABLE payments_2024 PARTITION OF payments
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
CREATE TABLE payments_2025 PARTITION OF payments
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

ALTER TABLE payments ADD PRIMARY KEY (order_id, transaction_date);

--   Song song hóa (Parallel Execution)
SET max_parallel_workers_per_gather = 4;



```

## Result

```sql

-- Test query
SELECT customer_id, SUM(amount_paid)
FROM payments
GROUP BY customer_id
ORDER BY SUM(amount_paid) DESC
LIMIT 10;

SELECT COUNT(*)
FROM payments
WHERE status = 'failed'
AND transaction_date > NOW() - INTERVAL '30 days';
```

Time Execution:

## END

I hope this post is helpful to you.
