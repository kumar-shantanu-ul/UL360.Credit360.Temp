-- Please update version.sql too -- this keeps clean builds in sync
define version=55
@update_header

-- link up any FORMULATED types that have been missed to product tags
DECLARE
    v_new_tag_id    tag.tag_id%TYPE;
    v_prod_cat_group_sid   tag_group.tag_group_sid%TYPE;
     v_num NUMBER;
BEGIN         

        FOR r IN (
            SELECT gt_product_type_id, description, gt_product_class_id, DECODE(gt_product_class_id, 1, ' (Fm)', 2, ' (Mn)' , 3, ' (Pk)') class_suffix  FROM gt_product_type 
            WHERE gt_product_type_id NOT IN (
                SELECT gt_product_type_id FROM gt_tag_product_type
            )  and gt_product_class_id = 1
        )
        LOOP
        
             FOR ap IN (
                SELECT app_sid, host FROM csr.customer WHERE host IN (
                    'bootssupplier.credit360.com',
                    'bootstest.credit360.com'
                )
            )
            LOOP
        SELECT tag_group_sid INTO v_prod_cat_group_sid FROM tag_group WHERE name = 'product_category' AND app_sid = ap.app_sid;
            -- insert into TAG a tag for each product type
            INSERT INTO tag (tag_id, tag, explanation) VALUES (tag_id_seq.nextval,  r.description ||r.class_suffix ,  r.description || r.class_suffix)
                RETURNING tag_id INTO v_new_tag_id;
                
            INSERT INTO tag_group_member (tag_group_sid, tag_id) VALUES (v_prod_cat_group_sid, v_new_tag_id);

            -- insert into GT_TAG_PRODUCT_TYPE a link between them
            INSERT INTO gt_tag_product_type (gt_product_type_id, tag_id) VALUES (r.gt_product_type_id, v_new_tag_id);

            -- set up the conditional questionnaires based on type 
            -- Form = Not Prod Design, Formulated
            -- Manufac = Prod Design, Not Formulated
            -- Parent Pack = Not Prod Design, Not Formulated
            
            IF r.gt_product_class_id = 1 THEN 
                INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_new_tag_id, 10, 1);
                INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_new_tag_id, 13, 0);            
            END IF;
            IF r.gt_product_class_id = 2 THEN 
                INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_new_tag_id, 10, 0);
                INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_new_tag_id, 13, 1);            
            END IF;
            IF r.gt_product_class_id = 3 THEN 
                INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_new_tag_id, 10, 0);
                INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_new_tag_id, 13, 0);            
            END IF;
            

            
            DBMS_OUTPUT.PUT_LINE('Created tag ' || v_new_tag_id  || 'for type ' || r.description || ' for host ' || ap.host);

            END LOOP;

        END LOOP;
    
    select count(*) into v_num from gt_product_type where gt_product_type_id not in (
    select gt_product_type_id from gt_tag_product_type
    ) 
        and gt_product_class_id = 1;
    DBMS_OUTPUT.PUT_LINE(v_num);
    
END;
/

INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id)
    SELECT tag_id, (SELECT tag_attribute_id FROM tag_attribute WHERE name = 'group_or_Product Type') FROM gt_tag_product_type 
    WHERE tag_id NOT IN (SELECT tag_id FROM tag_tag_attribute WHERE tag_attribute_id = (SELECT tag_attribute_id FROM tag_attribute WHERE name = 'group_or_Product Type'));

INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id)
    SELECT tag_id, (SELECT tag_attribute_id FROM tag_attribute WHERE name = 'lbl_Green Tick Assessment') FROM gt_tag_product_type
    WHERE tag_id NOT IN (SELECT tag_id FROM tag_tag_attribute WHERE tag_attribute_id = (SELECT tag_attribute_id FROM tag_attribute WHERE name = 'lbl_Green Tick Assessment'));

INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id)
    SELECT tag_id, (SELECT tag_attribute_id FROM tag_attribute WHERE name = 'child_needsGreenTick') FROM gt_tag_product_type 
    WHERE tag_id NOT IN (SELECT tag_id FROM tag_tag_attribute WHERE tag_attribute_id = (SELECT tag_attribute_id FROM tag_attribute WHERE name = 'child_needsGreenTick'));
	
-- pos must be more than needsGreenTick
UPDATE tag_group_member SET pos=8 WHERE tag_id IN (
    SELECT tag_id FROM gt_tag_product_type
);

BEGIN
    
    FOR r IN 
    (
        SELECT rownum rn, tag, tag_id FROM
        (
            SELECT t.* FROM gt_tag_product_type pt, tag t WHERE t.TAG_ID = pt.TAG_ID ORDER BY tag
        )
     )
     LOOP
        UPDATE tag_group_member SET pos = r.rn WHERE tag_id = r.tag_id;
        DBMS_OUTPUT.PUT_LINE(r.tag_id);
     END LOOP;
     
END;
/

@update_tail
