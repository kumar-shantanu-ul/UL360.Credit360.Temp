-- Please update version.sql too -- this keeps clean builds in sync
define version=1759
@update_header

ALTER TABLE CHAIN.PURCHASE
MODIFY(AMOUNT NUMBER(20,3));
	
@update_tail