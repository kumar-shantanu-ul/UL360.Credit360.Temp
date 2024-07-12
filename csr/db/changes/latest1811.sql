-- Please update version.sql too -- this keeps clean builds in sync
define version=1811
@update_header

--multi step process required on 11g
ALTER TABLE chain.customer_options ADD ADD_CSR_USER_TO_TOP_COMP NUMBER(1,0);
UPDATE chain.customer_options SET ADD_CSR_USER_TO_TOP_COMP = 1;
ALTER TABLE chain.customer_options MODIFY ADD_CSR_USER_TO_TOP_COMP NUMBER(1,0) DEFAULT 1 NOT NULL;
ALTER TABLE chain.customer_options ADD CHECK (ADD_CSR_USER_TO_TOP_COMP IN (0, 1));

@../supplier_body
 
@update_tail