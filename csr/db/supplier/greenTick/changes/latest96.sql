-- Please update version.sql too -- this keeps clean builds in sync
define version=96
@update_header

BEGIN
    -- correct the mispelt or out of sync product types
    FOR r IN ( 
        SELECT DISTINCT gt_product_type_id, description, trim_tag FROM (
            SELECT pt.gt_product_type_id, pt.description, REPLACE(REPLACE(REPLACE(t.tag, '(Mn) ', ''), '(Fm) ', ''), '(Pk) ', '') trim_tag FROM gt_product_type pt, gt_tag_product_type tpt, tag t WHERE t.tag_id = tpt.tag_id AND tpt.GT_PRODUCT_TYPE_ID = pt.GT_PRODUCT_TYPE_ID
        ) WHERE trim_tag <> description
    ) LOOP
        UPDATE gt_product_type SET description = r.trim_tag WHERE gt_product_type_id = r.gt_product_type_id;
        DBMS_OUTPUT.PUT_LINE('Updated "'|| r.description || '" to "' || r.trim_tag || '" for ' || r.gt_product_type_id);   
    END LOOP;

END;
/


DECLARE
    v_group_id  		questionnaire_group.group_id%TYPE;
    v_app_sid   		security_pkg.T_SID_ID;
	v_act				security_pkg.T_ACT_ID;
	v_tag_group_sid		security_pkg.T_SID_ID;
	v_tag_id			tag.tag_id%TYPE;
    v_pos				NUMBER;
    v_tag_attr_id		tag_attribute.tag_attribute_id%TYPE;
	v_needs_gt_tag_id	tag.tag_id%TYPE;
	v_no_pk_tag_id		tag.tag_id%TYPE;
BEGIN    

	---NOTE: WAS AN ISSUE WITH THIS BUT ONLY RUN ON test - SO 95 CORRECTS - 96 is CORRECT
	user_pkg.logonadmin('bootssupplier.credit360.com');
	SELECT sys_context('SECURITY','APP') INTO v_app_sid FROM dual;  
	SELECT sys_context('SECURITY','ACT') INTO v_act FROM dual;
	
	--updating tag group names to match new names of their corresponding product types...
	
	
	

	-- get product_category tag group
	v_tag_group_sid := securableobject_pkg.GetSidFromPath(v_act, v_app_sid, 'Supplier/TagGroups/product_category');

	-- Add needsGreenTick
	FOR r IN (
			SELECT  gt_product_type_id,  description, gt_product_class_id, DECODE(gt_product_class_id, 1, '(Fm) ', 2, '(Mn) ', 3, '(Pk) ') class_preffix  
			  FROM gt_product_type 
			 WHERE DECODE(gt_product_class_id, 1, '(Fm) ', 2, '(Mn) ', 3, '(Pk) ') || description NOT IN (SELECT t.tag
										 FROM tag t, tag_group_member tgm, tag_group tg
										WHERE tg.app_sid = v_app_sid
										  AND t.tag_id = tgm.tag_id
										  AND tgm.tag_group_sid = tg.tag_group_sid
										  AND tg.tag_group_sid = v_tag_group_sid) 
	)
	LOOP
		-- insert into TAG a tag for each new product type
		INSERT INTO tag (tag_id, tag, explanation) VALUES (tag_id_seq.nextval,  r.class_preffix || r.description, r.class_preffix || r.description)
			RETURNING tag_id INTO v_tag_id;

		INSERT INTO tag_group_member (tag_group_sid, tag_id, pos) VALUES (v_tag_group_sid, v_tag_id, 8);

		-- insert into GT_TAG_PRODUCT_TYPE a link between them
		INSERT INTO gt_tag_product_type (gt_product_type_id, tag_id) VALUES (r.gt_product_type_id, v_tag_id);

		-- set up the conditional questionnaires based on type 
		-- Form = Not Prod Design, Formulated
		-- Manufac = Prod Design, Not Formulated
		-- Parent Pack = Not Prod Design, Not Formulated
		IF r.gt_product_class_id = 1 THEN 
			INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 10, 1);
			INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 13, 0);
			--    INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 14, 0); 					
		END IF;
		IF r.gt_product_class_id = 2 THEN 
			INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 10, 0);
			INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 13, 1);      
			--    INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 14, 0); 					
		END IF;
		IF r.gt_product_class_id = 3 THEN 
			INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 10, 0);
			INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 13, 0);       
			--    INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 14, 0); 				
		END IF;
		-- TO DO - something like this for food
		--IF r.gt_product_class_id = 4 THEN 
		--    INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 10, 0);
		--    INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 13, 0);     
		--    INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 14, 1); 			
		--END IF;
		
		-- set up the remaining questionnaires
		INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 8, 1);
		INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 9, 1); 
		INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 11, 1); 
		INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 12, 1); 
		
		-- now add attributes for this tag
		INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_tag_id, 2); --lbl_Green Tick Assessment
		INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_tag_id, 6); --group_or_Product Type
		INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_tag_id, 7); --child_needsGreenTick
		

	END LOOP;
		


END;
/


@update_tail
