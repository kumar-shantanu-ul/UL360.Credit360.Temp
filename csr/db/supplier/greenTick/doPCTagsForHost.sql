DECLARE
    v_app_sid   		security_pkg.T_SID_ID;
	v_act				security_pkg.T_ACT_ID;
	v_tag_group_sid		security_pkg.T_SID_ID;
	v_tag_id			tag.tag_id%TYPE;
	v_needs_gt_tag_id	tag.tag_id%TYPE;
	v_no_pk_tag_id		tag.tag_id%TYPE;
BEGIN    

		user_pkg.logonadmin('&&1');
		SELECT sys_context('SECURITY','APP') INTO v_app_sid FROM dual;  
		SELECT sys_context('SECURITY','ACT') INTO v_act FROM dual;

		-- get product_category tag group
		v_tag_group_sid := securableobject_pkg.GetSidFromPath(v_act, v_app_sid, 'Supplier/TagGroups/product_category');

		-- Add needsGreenTick
		BEGIN
			tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'needsGreenTick', 'Product requires a Green Tick assessment', 1, 1, v_needs_gt_tag_id);
			INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_needs_gt_tag_id, 2); --lbl_Green Tick Assessment
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
			-- get the needsGreenTick tag id
			 SELECT t.tag_id INTO v_needs_gt_tag_id 
			   FROM tag t, tag_group_member tgm, tag_group tg 
			   WHERE t.tag = 'needsGreenTick' 
			   AND tg.app_sid = v_app_sid
			   AND t.tag_id = tgm.tag_id
			   AND tgm.tag_group_sid = tg.tag_group_sid;
		END;
		
		-- Add withoutPackaging
		BEGIN
			tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'withoutPackaging', 'Product does not include packaging', 6, 1, v_no_pk_tag_id);
			INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_no_pk_tag_id, 2); --lbl_Green Tick Assessment
			--INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_no_pk_tag_id, 2); --child_needsGreenTick
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
			-- get the withoutPackaging tag id
			 SELECT t.tag_id INTO v_no_pk_tag_id 
			   FROM tag t, tag_group_member tgm, tag_group tg 
			   WHERE t.tag = 'withoutPackaging' 
			   AND tg.app_sid = v_app_sid
			   AND t.tag_id = tgm.tag_id
			   AND tgm.tag_group_sid = tg.tag_group_sid;
		END;
	
--1) add new product types into tags	
		-- add tags for all the product types not present as tags already and link them to the gt prod types
        FOR r IN (
            SELECT  gt_product_type_id,  description, gt_product_class_id, DECODE(gt_product_class_id, 1, '(Fm) ', 2, '(Mn) ', 3, '(Pk) ', 4, '(Fd) ') class_preffix  
			  FROM gt_product_type 
			 WHERE DECODE(gt_product_class_id, 1, '(Fm) ', 2, '(Mn) ', 3, '(Pk) ', 4, '(Fd) ') || description NOT IN (
										SELECT t.tag
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
				INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 14, 0); 					
            END IF;
            IF r.gt_product_class_id = 2 THEN 
                INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 10, 0);
                INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 13, 1);      
				INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 14, 0); 					
            END IF;
            IF r.gt_product_class_id = 3 THEN 
                INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 10, 0);
                INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 13, 0);       
				INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 14, 0); 				
            END IF;
			-- TO DO - something like this for food
           IF r.gt_product_class_id = 4 THEN 
               INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 10, 0);
               INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 13, 0);     
			    INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 14, 1); 			
           END IF;
			
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
		
-- 2) delete any tags without associated product types
        FOR r IN (
            SELECT t.tag_id, t.tag
			  FROM tag t, tag_group_member tgm, tag_group tg
			 WHERE tg.app_sid = v_app_sid
			   AND t.tag_id = tgm.tag_id
			   AND tag IN ('(Fm)', '(Fd)', '(Mn)', '(Pk)')
			   AND tgm.tag_group_sid = tg.tag_group_sid
			   AND tg.tag_group_sid = v_tag_group_sid
			   AND t.tag_id NOT IN (SELECT tag_id FROM gt_tag_product_type)
		)
        LOOP
			DELETE FROM tag_tag_attribute WHERE tag_id = r.tag_id;			
			DELETE FROM tag_group_member WHERE tag_id = r.tag_id;	
			DELETE FROM questionnaire_tag WHERE tag_id = r.tag_id;				
			DELETE FROM tag WHERE tag_id = r.tag_id;
        END LOOP;

-- 3) finally update tags description and position alphabetically
-- TO DO



END;
/
commit;
exit

