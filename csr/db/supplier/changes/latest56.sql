-- Please update version.sql too -- this keeps clean builds in sync
define version=56
@update_header

-- making changes so can only create a revision when the product group is approved  - so this is redundant
ALTER TABLE SUPPLIER.PRODUCT_REVISION DROP COLUMN CREATED_STATUS;



@update_tail
