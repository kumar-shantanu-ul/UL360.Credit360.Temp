-- Please update version.sql too -- this keeps clean builds in sync
define version=69
@update_header

DECLARE
	v_max_range_id	gt_product_range.gt_product_range_id%TYPE;
BEGIN

	-- add new gt prod range range for live
	SELECT MAX(gt_product_range_id) INTO v_max_range_id FROM gt_product_range;
	
	INSERT INTO gt_product_range (gt_product_range_id, description) VALUES (v_max_range_id+1, 'Sub-Product');

END;
/

@update_tail