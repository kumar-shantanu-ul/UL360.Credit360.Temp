-- Please update version.sql too -- this keeps clean builds in sync
define version=2494
@update_header

ALTER TABLE ct.customer_options DROP CONSTRAINT CHK_REINVITE_SUPPLIER;
ALTER TABLE ct.customer_options DROP COLUMN reinvite_supplier;

ALTER TABLE chain.customer_options ADD reinvite_supplier NUMBER(1); 

UPDATE chain.customer_options 
   SET reinvite_supplier = 0;

ALTER TABLE chain.customer_options MODIFY reinvite_supplier DEFAULT 0 NOT NULL; 

ALTER TABLE chain.customer_options
ADD CONSTRAINT CHK_REINVITE_SUPPLIER CHECK (REINVITE_SUPPLIER IN (0,1));

@update_tail
