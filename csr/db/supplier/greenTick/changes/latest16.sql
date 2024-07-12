-- Please update version.sql too -- this keeps clean builds in sync
define version=16
@update_header



-- clear class tags from product and tag table - we're going to associate with product type now not class
DELETE FROM product_tag WHERE tag_id IN (
    SELECT tag_id FROM gt_tag_product_class
);

DELETE FROM product_revision_tag WHERE tag_id IN (
    SELECT tag_id FROM gt_tag_product_class
);

DELETE FROM questionnaire_tag WHERE tag_id IN (
    SELECT tag_id FROM gt_tag_product_class
);

DELETE FROM tag_group_member WHERE tag_id IN (
    SELECT tag_id FROM gt_tag_product_class
);

CREATE TABLE TEMP_TAG(
    TAG_ID                NUMBER(10, 0)    NOT NULL
)
;

INSERT INTO TEMP_TAG
    SELECT tag_id FROM gt_tag_product_class;

DROP TABLE gt_tag_product_class CASCADE CONSTRAINTS PURGE;

DELETE FROM tag_tag_attribute  WHERE tag_id IN (
    SELECT tag_id FROM TEMP_TAG
);

DELETE FROM tag WHERE tag_id IN (
    SELECT tag_id FROM TEMP_TAG
);

DROP TABLE TEMP_TAG CASCADE CONSTRAINTS PURGE;




-- add product type tag table
CREATE TABLE GT_TAG_PRODUCT_TYPE(
    GT_PRODUCT_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    TAG_ID                NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK323 PRIMARY KEY (GT_PRODUCT_TYPE_ID, TAG_ID)
)
;
ALTER TABLE GT_TAG_PRODUCT_TYPE ADD CONSTRAINT RefTAG863 
    FOREIGN KEY (TAG_ID)
    REFERENCES TAG(TAG_ID)
;
ALTER TABLE GT_TAG_PRODUCT_TYPE ADD CONSTRAINT RefGT_PRODUCT_TYPE864 
    FOREIGN KEY (GT_PRODUCT_TYPE_ID)
    REFERENCES GT_PRODUCT_TYPE(GT_PRODUCT_TYPE_ID)
;

-- set the tags for each type and the tags for each product up
-- set the tags for each type and the tags for each product up
DECLARE
    v_new_tag_id    tag.tag_id%TYPE;
     v_prod_cat_group_sid   tag_group.tag_group_sid%TYPE;
     
BEGIN 

    --loop round all possible hosts
    FOR ap IN (
        SELECT app_sid, host FROM csr.customer WHERE host IN (
            'bootssupplier.credit360.com',
            'bootstest.credit360.com',
            'bsstage.credit360.com',
            'bs.credit360.com'
        )
    )
    LOOP
    
        SELECT tag_group_sid INTO v_prod_cat_group_sid FROM tag_group WHERE name = 'product_category' AND app_sid = ap.app_sid;

        FOR r IN (
            SELECT gt_product_type_id, description, gt_product_class_id, DECODE(gt_product_class_id, 1, '(Fm) ', 2, '(Mn) ', 3, '(Pk) ') class_suffix  FROM gt_product_type 
        )
        LOOP
            -- insert into TAG a tag for each product type
            INSERT INTO tag (tag_id, tag, explanation) VALUES (tag_id_seq.nextval,  r.class_suffix || r.description,  r.description || r.class_suffix)
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
    
    
END;
/



-- link all existing products to a TAG that represents the type they have (insert into product tag) 
-- this ignores those with no types set - they normally won't happen but will be to be dealt with on rollout 
INSERT INTO product_tag (product_id, tag_id)
SELECT product_id, tag_id 
  FROM gt_product_answers a, gt_tag_product_type tpt 
 WHERE tpt.gt_product_type_id = a.gt_product_type_id
   AND revision_id = 1;
    
-- TO DO need to do this for all revisions - store tags by revision - but I don't think that's actually been finished
DECLARE
     v_questionnaire_group_id   questionnaire_group.group_id%TYPE;
     
BEGIN 

    --loop round all possible hosts
    FOR ap IN (
        SELECT app_sid, host FROM csr.customer WHERE host IN (
            'bootssupplier.credit360.com',
            'bootstest.credit360.com',
            'bsstage.credit360.com',
            'bs.credit360.com'
        )
    )
    LOOP
    
        SELECT group_id INTO v_questionnaire_group_id FROM questionnaire_group WHERE app_sid = ap.app_sid AND name = 'Green Tick';
        
        INSERT INTO product_revision_tag (product_id, revision_id, group_id, tag_id)
            SELECT product_id, revision_id, v_questionnaire_group_id , tag_id 
              FROM gt_product_answers a, gt_tag_product_type tpt 
             WHERE tpt.gt_product_type_id = a.gt_product_type_id;
    
    END LOOP;
    
END;
/

------ Set up tag attribute that groups types into a dropdown
UPDATE tag_attribute SET name = 'group_or_Product Type' WHERE name = 'group_or_Product Class';

INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id)
    SELECT tag_id, (SELECT tag_attribute_id FROM tag_attribute WHERE name = 'group_or_Product Type') FROM gt_tag_product_type;

INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id)
    SELECT tag_id, (SELECT tag_attribute_id FROM tag_attribute WHERE name = 'lbl_Green Tick Assessment') FROM gt_tag_product_type;	

INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id)
    SELECT tag_id, (SELECT tag_attribute_id FROM tag_attribute WHERE name = 'child_needsGreenTick') FROM gt_tag_product_type;
	
	
-- pos must be more than needsGreenTick
UPDATE tag_group_member SET pos=8 WHERE tag_id IN (
    SELECT tag_id FROM gt_tag_product_type
);

@update_tail