-- Please update version.sql too -- this keeps clean builds in sync
define version=17
@update_header

-- change the units flag (wether you enter weight or vol on the product info page) to be linked to the type not the class
ALTER TABLE SUPPLIER.GT_PRODUCT_CLASS DROP COLUMN UNITS;
ALTER TABLE SUPPLIER.GT_PRODUCT_CLASS DROP COLUMN UNITS_DESC;

ALTER TABLE SUPPLIER.GT_PRODUCT_TYPE ADD (UNIT VARCHAR2(20 BYTE));

-- for now all formulated in ml
UPDATE gt_product_type SET unit = 'ml' WHERE gt_product_class_id = 1;
UPDATE gt_product_type SET unit = 'g' WHERE gt_product_class_id = 2;
UPDATE gt_product_type SET unit = 'g' WHERE gt_product_class_id = 3;

ALTER TABLE SUPPLIER.GT_PRODUCT_TYPE
MODIFY(UNIT  NOT NULL);

@update_tail