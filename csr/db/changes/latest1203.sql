-- Please update version.sql too -- this keeps clean builds in sync
define version=1203
@update_header

ALTER TABLE CT.CUSTOMER_OPTIONS ADD (IS_VALUE_CHAIN NUMBER(1) DEFAULT 0);

UPDATE CT.CUSTOMER_OPTIONS 
   SET is_value_chain = 1 
 WHERE app_sid IN (
 	SELECT app_sid FROM csr.customer WHERE host in ('ct.credit360.com', 'ctdev.credit360.com')
 );

@update_tail
