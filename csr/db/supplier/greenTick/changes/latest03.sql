-- Please update version.sql too -- this keeps clean builds in sync
define version=3
@update_header

-- add new product design questionnaire
INSERT INTO questionnaire (
   questionnaire_id, active, class_name, 
   friendly_name, description, package_name) 
VALUES (13, 1, 'gtProductDesign',
    'Product Design', 'Product Design', 'gt_product_design_pkg');
	

	
DECLARE
	v_act					security_pkg.T_ACT_ID;
	v_app_sid				security_pkg.T_SID_ID;
	v_quest_group_sid		security_pkg.T_SID_ID;
BEGIN
	
	FOR r IN (SELECT app_sid, host FROM csr.customer WHERE host IN 
		(
			'bs.credit360.com',
			'bootstest.credit360.com',
			'bootssupplier.credit360.com',
			'bsstage.credit360.com'
		)
	)
	LOOP
		user_pkg.logonadmin(r.host);
		SELECT sys_context('SECURITY','APP') INTO v_app_sid FROM dual;  
		SELECT sys_context('SECURITY','ACT') INTO v_act FROM dual;
		
		SELECT qg.group_id INTO v_quest_group_sid 
		  FROM questionnaire_group qg
		 WHERE qg.app_sid = v_app_sid 
		   AND qg.name= 'Green Tick';
		
		INSERT INTO questionnaire_group_membership (questionnaire_id, group_id, pos)  VALUES (13, v_quest_group_sid, 13);
		
	END LOOP;
END;
/
	

-- set all existing GT products to use the new questionnaire but with the used set to 0 (the ones present already will all be "formulated")
INSERT INTO product_questionnaire_link 
    (product_id, questionnaire_id, questionnaire_status_id, used, due_date)
        SELECT product_id, 13 questionnaire_id, 1 questionnaire_status_id, 0 used, due_date  FROM product_questionnaire_link
         WHERE questionnaire_id = 12; -- just get one of the GT questionnaires 
		 
		 
		 
@update_tail