-- Please update version.sql too -- this keeps clean builds in sync
define version=88
@update_header
	
-- TABLE: GT_TRANS_ITEM 
--

	--summary: adding column gt_product_type.MNFCT_WATER_SCORE -- SHOULD BE NOT NULL - BUT WILL UPDATE IT FIRST
	-- set them to -1 for manufactured / parent packs produts 
	-- set them to 1 for formulated produts 
	--todo: GET THE REAL SCORES OFF ANDREW
	ALTER TABLE gt_product_type ADD mnfct_water_score NUMBER(10, 2);
	UPDATE gt_product_type SET mnfct_water_score = 1 WHERE gt_product_class_id = 1;
	UPDATE gt_product_type SET mnfct_water_score = -1 WHERE gt_product_class_id IN (2,3);
	ALTER TABLE gt_product_type MODIFY mnfct_water_score NOT NULL;
	
	--ADDING COLUMN FOR WATER_IN_PROD_PD - "HOW MUCH WATER IS THERE IN THE PRODUCT" FOR MANUFACTURED PRODUCTS
	
	ALTER TABLE gt_product_type ADD water_in_prod_pd NUMBER(10, 2);
	UPDATE gt_product_type SET water_in_prod_pd = 0;
	ALTER TABLE gt_product_type MODIFY water_in_prod_pd NOT NULL;
	
	-- adding column to the gt_material table for water impact of each material, used in calculating score_water_in_prod score for manufactured products
	
	ALTER TABLE gt_material ADD water_impact_score NUMBER(10, 2);
	UPDATE gt_material SET water_impact_score = 1;
	ALTER TABLE gt_material MODIFY water_impact_score NUMBER(10, 2);
	
	ALTER TABLE gt_profile ADD score_water_raw_mat NUMBER(10, 2);          --impact of water used extracting the raw materials
	ALTER TABLE gt_profile ADD score_water_contained NUMBER(10, 2);--impact of water used inside the product
	ALTER TABLE gt_profile ADD score_water_mnfct NUMBER(10, 2);            --impact of water used in the manufacturing process
	ALTER TABLE gt_profile ADD score_water_wsr NUMBER(10, 2);              -- modifier for using water from wsr...
	
	

@update_tail