-- Please update version.sql too -- this keeps clean builds in sync
define version=2757
@update_header

DECLARE 
	v_chain_sid 	security.security_pkg.T_SID_ID;
	v_company_type_groups_sid 	security.security_pkg.T_SID_ID;
	v_act_id				security.security_pkg.T_ACT_ID;
	v_app_sid				security.security_pkg.T_SID_ID;
	v_host VARCHAR2(255);
BEGIN
	security.user_pkg.logonadmin;
	
	--move company type groups into /Chain/CompanyTypeGroups container
	FOR r IN (
		SELECT ct.user_group_sid, c.host
		  FROM chain.company_type ct
		  JOIN csr.customer c ON ct.app_sid = c.app_sid
		 WHERE ct.user_group_sid IS NOT NULL
		 ORDER BY c.host
	)
	LOOP
		IF v_host IS NULL OR v_host <> r.host THEN
			security.user_pkg.logonadmin(r.host);
			--dbms_output.put_line('Logged in in:'||r.host);
			v_host := r.host;		
		END IF;
		
		v_act_id := security.security_pkg.GetAct;
		v_app_sid := security.security_pkg.GetApp;
		
		BEGIN
			v_chain_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Chain');
			v_company_type_groups_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_chain_sid, 'CompanyTypeGroups');
			
		EXCEPTION 
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.securableobject_pkg.CreateSO(v_act_id, v_chain_sid, security.security_pkg.SO_CONTAINER, 'CompanyTypeGroups', v_company_type_groups_sid);
						
				security.acl_pkg.AddACE(
					v_act_id, 
					security.acl_pkg.GetDACLIDForSID(v_company_type_groups_sid), 
					-1, 
					security.security_pkg.ACE_TYPE_ALLOW, 
					security.security_pkg.ACE_FLAG_DEFAULT, 
					security.securableobject_pkg.GetSidFromPath(v_act_id, security.security_pkg.getApp, 'Users/UserCreatorDaemon'), 
					security.security_pkg.PERMISSION_STANDARD_ALL
				);	

				security.acl_pkg.PropogateACEs(v_act_id, v_company_type_groups_sid);
		END;	
		
		security.securableobject_pkg.MoveSO(
			in_act_id			=> v_act_id,
			in_sid_id			=> r.user_group_sid,
			in_new_parent_sid	=> v_company_type_groups_sid
		);

	END LOOP;
	security.user_pkg.logonadmin;
END;
/

@../chain/company_type_body

@update_tail

