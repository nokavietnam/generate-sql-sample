CREATE TABLE payments (
    order_id BIGINT PRIMARY KEY, 
    payment_method VARCHAR(20), 
    amount_paid NUMERIC(10, 2)
);

-- Tạo sequence
CREATE SEQUENCE payment_seq
    START WITH 21243721
    INCREMENT BY 1
    NO CYCLE;
