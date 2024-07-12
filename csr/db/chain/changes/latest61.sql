define version=61
@update_header

ALTER TABLE CUSTOMER_OPTIONS ADD (DEFAULT_URL  VARCHAR2(4000));

@..\chain_pkg
@..\chain_body

@update_tail
