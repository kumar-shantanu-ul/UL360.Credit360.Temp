-- Please update version.sql too -- this keeps clean builds in sync
define version=54

@update_header

ALTER TABLE SUPPLIER.GT_PRODUCT_TYPE
ADD (HRS_USED_PER_MONTH NUMBER DEFAULT -1 NOT NULL);

@update_tail