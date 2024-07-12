
-- Please update version.sql too -- this keeps clean builds in sync
define version=63
@update_header

DECLARE
	v_tag_id 			tag.tag_id%TYPE;
	v_tag_group_sid		tag_group.tag_group_sid%TYPE;
BEGIN

	SELECT tag_group_sid INTO v_tag_group_sid
	  FROM tag_group 
	 --WHERE app_sid = (SELECT app_sid FROM csr.customer WHERE host = 'bs.credit360.com')
	WHERE app_sid = (SELECT app_sid FROM csr.customer WHERE host = 'bootstest.credit360.com')
	   AND name = 'product_category';

	-- Look round product types of class 3
	FOR r IN (
		SELECT gt_product_type_id, description FROM gt_product_type WHERE gt_product_class_id = 3
	) 
	LOOP
		-- insert into new tag for parent pack
		INSERT INTO tag (tag_id, tag, explanation) VALUES (tag_id_seq.nextval, '(Pk) '||r.description, '(Pk) '||r.description) RETURNING tag_id INTO v_tag_id; 
		
		-- insert intp prod cat group
		INSERT INTO tag_group_member (tag_group_sid, tag_id, pos, is_visible) VALUES (v_tag_group_sid, v_tag_id, v_tag_id, 1);

		-- link to prod type
		INSERT INTO gt_tag_product_type (gt_product_type_id, tag_id) VALUES (r.gt_product_type_id, v_tag_id);
		
		-- set up attributes
		INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_tag_id, 2);
		INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_tag_id, 6);
		INSERT INTO tag_tag_attribute (tag_id, tag_attribute_id) VALUES (v_tag_id, 7);
	
		-- link tag to questionnaires -> no PD or formulation
		INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 10, 0);
		INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) VALUES (v_tag_id, 13, 0);
	END LOOP;
		
END;
/

@update_tail