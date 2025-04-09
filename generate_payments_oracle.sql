CREATE OR REPLACE PROCEDURE generate_payments(p_num_payments IN NUMBER) AS 
    TYPE t_order_id IS TABLE OF payments.order_id%TYPE INDEX BY PLS_INTEGER;
    TYPE t_payment_method IS TABLE OF payments.payment_method%TYPE INDEX BY PLS_INTEGER;
    TYPE t_amount_paid IS TABLE OF payments.amount_paid%TYPE INDEX BY PLS_INTEGER;

    v_order_id        t_order_id;
    v_payment_method  t_payment_method;
    v_amount_paid     t_amount_paid;

    v_batch_size      CONSTANT PLS_INTEGER := 500;
    v_batch_index     PLS_INTEGER := 0;
BEGIN
  FOR i IN 1..p_num_payments LOOP
    v_batch_index := v_batch_index + 1;

    v_order_id(v_batch_index) := MOD(i, 1000000) + 21243720 + 1;
    v_payment_method(v_batch_index) := CASE WHEN MOD(i, 2) = 0 THEN 'Credit Card' ELSE 'PayPal' END;
    v_amount_paid(v_batch_index) := ROUND(DBMS_RANDOM.VALUE(10, 500), 2);
    IF v_batch_index = v_batch_size OR i = p_num_payments THEN 
      FORALL j IN 1..v_batch_index
        INSERT INTO payments (order_id, payment_method, amount_paid)
        VALUES (v_order_id(j), v_payment_method(j), v_amount_paid(j));
      COMMIT;

      -- reset batch 
      v_batch_index := 0;
      v_order_id.DELETE;
      v_payment_method.DELETE;
      v_amount_paid.DELETE;      
    END IF;
  END LOOP;
END generate_payments;
