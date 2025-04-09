# generate-sql-sample

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
        ROLLBACK; -- Dòng này gây lỗi [2D000]
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

## END
