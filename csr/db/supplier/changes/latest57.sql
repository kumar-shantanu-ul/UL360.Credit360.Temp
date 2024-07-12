-- Please update version.sql too -- this keeps clean builds in sync
define version=57
@update_header


-- Move the constraint to point to the Product Info data instead of the transport data
-- Note, on my machine, the constraint was SYS_C0026568
ALTER TABLE SUPPLIER.GT_COUNTRY_SOLD_IN DROP CONSTRAINT SYS_C00160405;

ALTER TABLE SUPPLIER.GT_COUNTRY_SOLD_IN ADD 
CONSTRAINT SYS_C00160405
 FOREIGN KEY (PRODUCT_ID, REVISION_ID)
 REFERENCES SUPPLIER.GT_PRODUCT_ANSWERS (PRODUCT_ID, REVISION_ID)
 ENABLE
 VALIDATE;


@update_tail
