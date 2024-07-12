-- Please update version.sql too -- this keeps clean builds in sync
define version=79
@update_header

DECLARE
	v_max_id NUMBER;
BEGIN

	SELECT MAX(gt_product_range_id)+1 INTO v_max_id FROM gt_product_range;

	INSERT INTO gt_product_range (gt_product_range_id, description) VALUES (v_max_id, 'Soap and Glory');

	INSERT INTO gt_user_report_product_ranges (csr_user_sid, gt_product_range_id) 
		SELECT DISTINCT csr_user_sid, v_max_id
			FROM gt_user_report_product_ranges;

END;
/

@update_tail