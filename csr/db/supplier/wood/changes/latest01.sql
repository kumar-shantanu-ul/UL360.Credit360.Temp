-- Please update version.sql too -- this keeps clean builds in sync
define version=1
@update_header
    
DECLARE
	v_act					security_pkg.T_ACT_ID;
	v_app_sid				security_pkg.T_SID_ID;
	v_tag_id				tag.tag_id%TYPE;
BEGIN
	
	INSERT INTO TAG_ATTRIBUTE VALUES(3, 'lbl_Sustainable Sourcing', 'A tag that is associated with sustainable sourcing. e.g. "containsWood"'); 

	
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

		--label the tags as sustainable sourcing
		
		SELECT t.tag_id INTO v_tag_id 
		  FROM tag t, tag_group_member tgm, tag_group tg 
		 WHERE tag = 'containsWood' 
		   AND t.tag_id = tgm.tag_id
		   AND tgm.tag_group_sid = tg.tag_group_sid
		   AND app_sid = sys_context('SECURITY','APP') ;
		
		INSERT INTO TAG_TAG_ATTRIBUTE VALUES(v_tag_id,3);
		
		SELECT t.tag_id INTO v_tag_id 
		  FROM tag t, tag_group_member tgm, tag_group tg 
		 WHERE tag = 'containsPulp' 
		   AND t.tag_id = tgm.tag_id
		   AND tgm.tag_group_sid = tg.tag_group_sid
		   AND app_sid = sys_context('SECURITY','APP') ;
		
		INSERT INTO TAG_TAG_ATTRIBUTE VALUES(v_tag_id,3);
		
		SELECT t.tag_id INTO v_tag_id 
		  FROM tag t, tag_group_member tgm, tag_group tg 
		 WHERE tag = 'containsPaper' 
		   AND t.tag_id = tgm.tag_id
		   AND tgm.tag_group_sid = tg.tag_group_sid
		   AND app_sid = sys_context('SECURITY','APP') ;
		
		INSERT INTO TAG_TAG_ATTRIBUTE VALUES(v_tag_id,3);
		
		SELECT t.tag_id INTO v_tag_id 
		  FROM tag t, tag_group_member tgm, tag_group tg 
		 WHERE tag = 'containsNaturalProducts' 
		   AND t.tag_id = tgm.tag_id
		   AND tgm.tag_group_sid = tg.tag_group_sid
		   AND app_sid = sys_context('SECURITY','APP') ;
		   
		INSERT INTO TAG_TAG_ATTRIBUTE VALUES(v_tag_id,3);
		
	
		
	END LOOP;
END;
/
@update_tail