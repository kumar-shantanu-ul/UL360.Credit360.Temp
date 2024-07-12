-- Please update version.sql too -- this keeps clean builds in sync
define version=14
@update_header

-- water pct score on formulation
ALTER TABLE gt_formulation_answers ADD (water_pct NUMBER(6,3));

-- update new field to be current average water pct
-- copy over the product water pct - even  though this will make formulation % summ to more that 100 
BEGIN 
    FOR r IN (
        SELECT pt.*, revision_id, product_id FROM gt_product_answers pa, gt_product_type pt 
        WHERE pa.GT_PRODUCT_TYPE_ID = pt.GT_PRODUCT_TYPE_ID
        AND product_id in (select product_id FROM product) 
    ) 
    LOOP
    
        UPDATE gt_formulation_answers SET water_pct = r.av_water_content_pct
            WHERE product_id = r.product_id
            AND revision_id = r.revision_id;
    
    END LOOP;
END;
/

-- reopen all formulation questionnaires as they now need data (looking at at least) 
UPDATE product_questionnaire 
   SET questionnaire_status_id = 1 
 WHERE questionnaire_status_id = 2
   AND questionnaire_id = 10; 
   

-- reopen all GT groups 
-- reopen all GT that are not Data Being Entered 
UPDATE  product_questionnaire_group pqg
   SET group_status_id = 1
 WHERE group_id IN (
    SELECT group_id FROM questionnaire_group WHERE name = 'Green Tick'
)
AND group_status_id > 1;
   

-- FORMULATED now uses the water pct set on the formulation questionnaire 
ALTER TABLE GT_PRODUCT_TYPE MODIFY(av_water_content_pct  NULL);
UPDATE gt_product_type SET av_water_content_pct = NULL WHERE gt_product_class_id = 1 ;


@update_tail