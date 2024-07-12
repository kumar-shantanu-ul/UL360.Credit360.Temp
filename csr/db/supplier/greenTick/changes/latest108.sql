-- Please update version.sql too -- this keeps clean builds in sync
define version=108
@update_header 

-- started flag was 1 / 2 not 1 / 0 ?
ALTER TABLE SUPPLIER.GT_PRODUCT_USER
MODIFY(STARTED  DEFAULT 0);

UPDATE SUPPLIER.GT_PRODUCT_USER SET STARTED = 0 WHERE STARTED = 1;
UPDATE SUPPLIER.GT_PRODUCT_USER SET STARTED = 1 WHERE STARTED = 2;

@..\model_pd_pkg.sql
@..\product_info_body.sql
@..\gt_food_body.sql
@..\gt_formulation_body.sql
@..\gt_packaging_body.sql
@..\gt_product_design_body.sql
@..\gt_supplier_body.sql
@..\gt_transport_body.sql

@update_tail