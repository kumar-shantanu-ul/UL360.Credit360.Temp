-- Please update version.sql too -- this keeps clean builds in sync
define version=5
@update_header

	-- rename column to capture the weight of the product excluding the packaging 
	ALTER TABLE gt_packaging_answers RENAME COLUMN prod_weight_inc_pack to prod_weight_exc_pack;

DECLARE
	v_pack_weight_total		gt_pack_item.weight_grams%TYPE;
	CURSOR c IS 
		SELECT * FROM gt_packaging_answers FOR UPDATE;
BEGIN


	-- Go over existing data and align the column value 
	FOR r IN c
	LOOP
		
		-- get the sum of packaging
		SELECT NVL(SUM(weight_grams),0) 
		  INTO v_pack_weight_total
		  FROM gt_pack_item
		 WHERE product_id = r.product_id
		   AND revision_id = r.revision_id;
		
		-- update current row
		UPDATE gt_packaging_answers SET prod_weight_exc_pack = r.prod_weight_exc_pack - v_pack_weight_total
		WHERE CURRENT OF c;
	
	END LOOP;
	
	
	
END;
/

	-- Changes to packaging questionnaire
	INSERT INTO gt_pack_layers_type(gt_pack_layers_type_id, description, pos) VALUES (4, 'Double walled jar', 4);

	ALTER TABLE gt_packaging_answers DROP COLUMN pack_for_protection;
	DROP TABLE gt_pa_pack_req;
	DROP TABLE gt_pack_req_type;

	ALTER TABLE gt_packaging_answers ADD (
	  prod_pack_occupation 			NUMBER(10,0),
	  pack_style_type	 			NUMBER(10,0)
	);
	-- Add columns to capture the justification report
	ALTER TABLE gt_packaging_answers ADD (
	  dbl_walled_jar_just 			NUMBER(10,0), -- bit field
	  contain_tablets_just   		NUMBER(10,0), -- bit field
	  tablets_in_blister_tray 		NUMBER(10,0) -- bit field
	);
	ALTER TABLE gt_packaging_answers ADD (
	  carton_gift_box_just			NUMBER(10,0), -- bit field
	  carton_gift_box_vacuum_form	NUMBER(10,0), -- drop down field
	  carton_gift_box_clear_win		NUMBER(10,0), -- drop down field
	  carton_gift_box_sleeve		NUMBER(10,0) -- drop down field
	);
	ALTER TABLE gt_packaging_answers ADD (
	  other_prod_protection_just		CLOB, 
	  other_pack_manu_proc_just			CLOB,  
	  other_pack_fill_proc_just			CLOB,  
	  other_logistics_just				CLOB,
	  other_prod_present_market_just	CLOB,
	  other_consumer_accept_just		CLOB,
	  other_prod_info_just				CLOB,
	  other_prod_safety_just			CLOB,
	  other_prod_legislation_just		CLOB,
	  other_issues_just					CLOB
	);
	ALTER TABLE gt_packaging_answers ADD (
	  just_report_explanation			CLOB
	);
	
@update_tail