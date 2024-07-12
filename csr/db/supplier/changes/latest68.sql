-- Please update version.sql too -- this keeps clean builds in sync
define version=68
@update_header


ALTER TABLE SUPPLIER.GT_FORMULATION_ANSWERS
ADD (no_haz_chem NUMBER(1) DEFAULT 0 NOT NULL);



UPDATE gt_formulation_answers gtfa
SET no_haz_chem = (SELECT DECODE(count(*), 0, 0, 1) FROM gt_fa_haz_chem WHERE product_id = gtfa.product_id AND revision_id = gtfa.revision_id)
WHERE product_id IN 
(SELECT product_id FROM product_questionnaire_group WHERE group_status_id = 3);

@update_tail
