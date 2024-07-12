-- Please update version.sql too -- this keeps clean builds in sync
define version=15
@update_header

-- non scored fields
ALTER TABLE gt_packaging_answers ADD (total_trans_pack_weight NUMBER(10,2));
ALTER TABLE gt_packaging_answers ADD (num_packs_per_outer NUMBER(10,0));

-- reopen all packaging questionnaires where closed as new fields
UPDATE product_questionnaire 
   SET questionnaire_status_id = 1 
 WHERE questionnaire_status_id = 2
   AND questionnaire_id = 9; 


@update_tail