-- Please update version.sql too -- this keeps clean builds in sync
define version=9
@update_header

-- insert new supplier option
	INSERT INTO gt_sus_relation_type (gt_sus_relation_type_id, description, gt_score, pos) VALUES (6 , 'Supplier has been audited. (SA and Quality). Management plan in place - results NOT signed off', 4, 3);
	UPDATE gt_sus_relation_type SET pos = 4 WHERE gt_sus_relation_type_id = 3;
	UPDATE gt_sus_relation_type SET pos = 5 WHERE gt_sus_relation_type_id = 4;	
	UPDATE gt_sus_relation_type SET pos = 6 WHERE gt_sus_relation_type_id = 5;	
	
@update_tail