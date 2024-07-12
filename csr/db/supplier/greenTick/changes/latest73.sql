-- Please update version.sql too -- this keeps clean builds in sync
define version=73
@update_header


DECLARE
	v_tag_id 			tag.tag_id%TYPE;
BEGIN

	-- map prod types not already mapped to product_category tags 
	FOR r IN (
		SELECT tag_group_sid FROM tag_group WHERE app_sid in 
		(
			SELECT app_sid FROM csr.customer WHERE ((host = 'bootssupplier.credit360.com') OR (host = 'bootstest.credit360.com') OR (host = 'bs.credit360.com'))
		)
		AND name = 'product_category'
	) 
	LOOP

		FOR t IN
		(
			SELECT * FROM gt_product_type WHERE gt_product_type_id NOT IN 
			(
				SELECT gt_product_type_id 
				  FROM gt_tag_product_type tpt, tag_group_member tgm, tag_group tg
				 WHERE tpt.tag_id = tgm.tag_id
				   AND tgm.tag_group_sid = tg.tag_group_sid
				   AND tg.tag_group_sid = r.tag_group_sid
			)
		)
		LOOP 
		
			-- insert into new tag 
			IF t.gt_product_class_id = 1 THEN 
				INSERT INTO tag (tag_id, tag, explanation) VALUES (tag_id_seq.nextval, '(Fm) '||t.description, '(Fm) '||t.description) RETURNING tag_id INTO v_tag_id;
			END IF;
			IF t.gt_product_class_id = 2 THEN 
				INSERT INTO tag (tag_id, tag, explanation) VALUES (tag_id_seq.nextval, '(Mn) '||t.description, '(Mn) '||t.description) RETURNING tag_id INTO v_tag_id;
			END IF;
			IF t.gt_product_class_id = 3 THEN 
				INSERT INTO tag (tag_id, tag, explanation) VALUES (tag_id_seq.nextval, '(Pk) '||t.description, '(Pk) '||t.description) RETURNING tag_id INTO v_tag_id;
			END IF;
			
			-- insert intp prod cat group
			INSERT INTO tag_group_member (tag_group_sid, tag_id, pos, is_visible) VALUES (r.tag_group_sid, v_tag_id, v_tag_id, 1);

			-- link to prod type
			INSERT INTO gt_tag_product_type (gt_product_type_id, tag_id) VALUES (t.gt_product_type_id, v_tag_id);
			
			-- set up attributes
			INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_tag_id, 2);
			INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_tag_id, 6);
			INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_tag_id, 7);
		
			-- link tag to questionnaires -> no formulation
			IF t.gt_product_class_id = 1 THEN 
				INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 13, 0);
			END IF;
			IF t.gt_product_class_id = 2 THEN 
				INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 10, 0);
			END IF;
			IF t.gt_product_class_id = 3 THEN 
				INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 13, 0);
				INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 10, 0);
			END IF;
			
		END LOOP;
		
	END LOOP;

END;
/


@update_tail