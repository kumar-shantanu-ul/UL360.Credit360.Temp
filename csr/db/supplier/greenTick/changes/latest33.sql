-- Please update version.sql too -- this keeps clean builds in sync
define version=33
@update_header

ALTER TABLE SUPPLIER.GT_PRODUCT_ANSWERS DROP COLUMN UNUSED_GT_PRODUCT_TYPE_ID;

		
@update_tail