--this table has RLS. not sure if this will work
ALTER TABLE ct.customer_options ADD hide_ec NUMBER(1); 
ALTER TABLE ct.customer_options ADD hide_bt NUMBER(1); 
ALTER TABLE ct.customer_options ADD copy_to_indicators NUMBER(1); 

UPDATE ct.customer_options 
   SET hide_ec = 0, 
   hide_bt = 0, 
   copy_to_indicators= 0;

ALTER TABLE ct.customer_options MODIFY hide_ec DEFAULT 0 NOT NULL; 
ALTER TABLE ct.customer_options MODIFY hide_bt DEFAULT 0 NOT NULL; 
ALTER TABLE ct.customer_options MODIFY copy_to_indicators DEFAULT 0 NOT NULL; 
