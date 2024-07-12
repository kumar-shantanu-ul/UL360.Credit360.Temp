-- Please update version.sql too -- this keeps clean builds in sync
define version=35
@update_header

-- link up manufactured for the bootstest site only atm
DECLARE
    v_tag_id NUMBER;
    v_group_sid NUMBER;
BEGIN 
    

    select tag_group_sid INTO v_group_sid 
      from tag_group WHERE name = 'product_category' 
       AND app_sid = (SELECT app_sid FROM csr.customer WHERE host = 'bootstest.credit360.com');

    FOR r IN 
    (
        SELECT * FROM gt_product_type WHERE gt_product_class_id = 2
            ORDER BY lower(description)
    )
    LOOP
        --DBMS_OUTPUT.PUT_LINE(r.gt_product_type_id);
        INSERT INTO tag (tag_id, tag, explanation) VALUES (tag_id_seq.nextval, '(Mn) '||r.description, '(Mn) '||r.description) RETURNING tag_id INTO v_tag_id;
        
        -- link PT  to tag 
        INSERT INTO gt_tag_product_type (tag_id, gt_product_type_id) VALUES (v_tag_id, r.gt_product_type_id); 
        
        -- map to Product Design and NOT to Formulation 
        INSERT INTO questionnaire_tag  (tag_id, questionnaire_id, mapped)  VALUES(v_tag_id, 10, 0);
        INSERT INTO questionnaire_tag  (tag_id, questionnaire_id, mapped)  VALUES(v_tag_id, 13, 1);
        
        -- set up attribtes 
        INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_tag_id, 2);
        INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_tag_id, 6);
        INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_tag_id, 7);
        
        -- link to tag group 
        INSERT INTO tag_group_member (tag_group_sid, tag_id, pos) VALUES (v_group_sid, v_tag_id,  v_tag_id);
        
    END LOOP;
END;
/
	
		
		
@update_tail