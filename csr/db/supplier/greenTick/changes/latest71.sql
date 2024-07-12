-- Please update version.sql too -- this keeps clean builds in sync
define version=71
@update_header

ALTER TABLE SUPPLIER.GT_PRODUCT_TYPE
 ADD (MAINS_POWERED  NUMBER(1)  DEFAULT 0 NOT NULL);
 


@update_tail