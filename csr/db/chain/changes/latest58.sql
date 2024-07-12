define version=58
@update_header

ALTER TABLE CHAIN.CUSTOMER_OPTIONS
ADD (PRODUCT_URL VARCHAR2(4000 CHAR));

@update_tail
