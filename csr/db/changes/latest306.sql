-- Please update version.sql too -- this keeps clean builds in sync
define version=306
@update_header

BEGIN
	BEGIN
		 INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, PARAMS_XML ) VALUES (   
			20, 'Generic mailout',                                                    
			'<params>'||                                                              
				'<param name="FROM_NAME"/>'||                                         
				'<param name="FROM_EMAIL"/>'||                                        
				'<param name="FROM_FRIENDLY_NAME"/>'||                                
				'<param name="FROM_USER_NAME"/>'||                                    
				'<param name="FULL_NAME"/>'||                                         
				'<param name="EMAIL"/>'||                                             
				'<param name="FRIENDLY_NAME"/>'||                                     
				'<param name="USER_NAME"/>'||                                         
			'</params>'                                                               
		 );                                                                           
	EXCEPTION
		WHEN OTHERS THEN 
			UPDATE ALERT_TYPE SET PARAMS_XML = 
				'<params>'||
					'<param name="FROM_NAME"/>'||
					'<param name="FROM_EMAIL"/>'||
					'<param name="FROM_FRIENDLY_NAME"/>'||
					'<param name="FROM_USER_NAME"/>'||
					'<param name="FULL_NAME"/>'||
					'<param name="EMAIL"/>'||
					'<param name="FRIENDLY_NAME"/>'||
					'<param name="USER_NAME"/>'||
				'</params>'
			WHERE ALERT_TYPE_ID = 20;
	END;
END;
/

insert into customer_alert_type (app_sid, alert_type_id) 
	select app_sid, 20 
	  from customer 
	 where host IN (
		'c360.telekom.de',
		'c360-test.telekom.de',
		'telekom-internal.telekom.de'
	)
	UNION
	select app_sid, 20
	  from customer_alert_type
	 where alert_type_id = 27;

delete from alert_template 
 where app_sid in (
	select app_sid from customer_alert_type where alert_type_Id = 27
   )
   and alert_type_id = 20;

update alert_template 
	set alert_type_id = 20 
 where  alert_type_Id = 27;

delete from customer_alert_type where alert_type_id =27;

delete from alert_type where alert_type_id =27;



-- for every sub-delegation:
-- * ensure parent-delegation has PERMISSION_STANDARD_DELEGATOR	ACE
-- * ensure delegation itself has PERMISSION_STANDARD_DELEGEE and NOT PERMISSION_STANDARD_DELEGATOR
DECLARE
	v_act	security_pkg.T_ACT_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 10000, v_act);
	-- find all subdelegations where DELEGATOR doesn't have PERMISSION_STANDARD_DELEGATOR permissions (and add it in)
	FOR r IN (
		SELECT delegation_sid, parent_sid
		  FROM delegation
		 WHERE delegation_sid IN (
			SELECT delegation_sid
			  FROM delegation
			 WHERE parent_sid != app_sid
			 MINUS
			SELECT delegation_sid
			  FROM delegation d, SECURITY.securable_object so, SECURITY.acl
			 WHERE d.delegation_sid = so.sid_id
			   AND so.dacl_id = acl.acl_id
			   AND acl.sid_id = d.parent_sid -- delegator
			   AND acl.permission_set = 263139 -- csr_data_pkg.PERMISSION_STANDARD_DELEGATOR
		)
	)
	LOOP
		-- add object to the DACL (the delegation is a group, so it has permissions on itself to generally read/write but not alter itself)
		acl_pkg.AddACE(v_act, acl_pkg.GetDACLIDForSID(r.delegation_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, r.parent_sid, csr_data_pkg.PERMISSION_STANDARD_DELEGATOR);
        acl_pkg.PropogateACEs(v_act, r.delegation_sid);
	END LOOP;
	
	-- delete ACEs WHERE from all subdelegations where delegee has PERMISSION_STANDARD_DELEGATOR
	FOR r IN (
		SELECT delegation_sid, acl.acl_id
		  FROM delegation d, SECURITY.securable_object so, SECURITY.acl
		 WHERE d.delegation_sid = so.sid_id
		   AND d.app_sid != parent_sid -- subdelegs
		   AND so.dacl_id = acl.acl_id
		   AND acl.sid_id = d.delegation_sid -- delegee
		   AND acl.permission_set = 263139 -- csr_data_pkg.PERMISSION_STANDARD_DELEGATOR
	)
	LOOP
		DELETE FROM security.ACL
		 WHERE permission_set = csr_data_pkg.PERMISSION_STANDARD_DELEGATOR
		   AND acl_id = r.acl_id
		   AND sid_id = r.delegation_sid;
        acl_pkg.PropogateACEs(v_act, r.delegation_sid);
	END LOOP;

	-- find all subdelegations where delegee isn't in ACE (and then give them PERMISSION_STANDARD_DELEGEE)
	FOR r IN (
		SELECT delegation_sid
		  FROM delegation
		 WHERE parent_sid != app_sid
		 MINUS
		SELECT delegation_sid
		  FROM delegation d, SECURITY.securable_object so, SECURITY.acl
		 WHERE d.delegation_sid = so.sid_id
		   AND so.dacl_id = acl.acl_id
		   AND acl.sid_id = d.delegation_sid -- delegee
		   AND acl.permission_set = 995 -- csr_data_pkg.PERMISSION_STANDARD_DELEGEE
	)
	LOOP
		-- add object to the DACL (the delegation is a group, so it has permissions on itself to generally read/write but not alter itself)
		acl_pkg.AddACE(v_act, acl_pkg.GetDACLIDForSID(r.delegation_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, r.delegation_sid, csr_data_pkg.PERMISSION_STANDARD_DELEGEE);
        acl_pkg.PropogateACEs(v_act, r.delegation_sid);
	END LOOP;
END;
/


@../csr_data_pkg
@../csr_data_body
@../alert_pkg
@../alert_body
@../csr_user_pkg
@../csr_user_body
@../delegation_body

@update_tail
