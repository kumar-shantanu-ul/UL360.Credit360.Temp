-- Please update version.sql too -- this keeps clean builds in sync
define version=18
@update_header

-- Set up the ability to set product weight inc or exc packaging. Move the cols to Prod Answers table
ALTER TABLE SUPPLIER.GT_PRODUCT_ANSWERS
 ADD (PROD_WEIGHT  NUMBER(10,2));

ALTER TABLE SUPPLIER.GT_PRODUCT_ANSWERS
 ADD (WEIGHT_INC_PKG  NUMBER(1)              DEFAULT 0);

 -- copy data from packaging table
 BEGIN
    FOR r IN (
        SELECT prod_weight_exc_pack, product_id, revision_id FROM gt_packaging_answers 
    )
    LOOP
        UPDATE gt_product_answers SET prod_weight = r.prod_weight_exc_pack WHERE product_id = r.product_id AND revision_id = r.revision_id;
    END LOOP;
END;
/

-- remove the pack column
ALTER TABLE SUPPLIER.GT_PACKAGING_ANSWERS DROP COLUMN PROD_WEIGHT_EXC_PACK;

-- rename the product type column in product answers - this is all controlled by tags now
-- will drop later - just want to disable for now
ALTER TABLE SUPPLIER.GT_PRODUCT_ANSWERS
	RENAME COLUMN GT_PRODUCT_TYPE_ID TO UNUSED_GT_PRODUCT_TYPE_ID;


@update_tail