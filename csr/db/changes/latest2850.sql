-- Please update version.sql too -- this keeps clean builds in sync
define version=2850
define minor_version=0
@update_header

SET SERVEROUTPUT ON

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

SET DEFINE OFF
BEGIN
	UPDATE csr.module
	   SET description = 'Enable Frameworks for Core (GRI & CDP only). Setup instructions: <a href="http://emu.helpdocsonline.com/frameworks" target="_blank">http://emu.helpdocsonline.com/frameworks</a>'
	 WHERE module_name = 'Frameworks';
END;
/
SET DEFINE ON

-- Move module so from application to indexes container
DECLARE
	v_act_id				security.security_pkg.T_ACT_ID;
	v_app_sid				security.security_pkg.T_SID_ID;
	v_indexes_root_sid		security.security_pkg.T_SID_ID;
	v_dacl_id				security.security_pkg.T_ACL_ID;
	v_acl_id				security.security_pkg.T_ACL_ID;
	v_acl_index				security.security_pkg.T_ACL_INDEX;
	v_ace_type				security.security_pkg.T_ACE_TYPE;
	v_ace_flags				security.security_pkg.T_ACE_FLAGS;
	v_sid_id				security.security_pkg.T_SID_ID;
	v_permission_set		security.security_pkg.T_PERMISSION;
	v_reg_users_sid			security.security_pkg.T_SID_ID;
	out_cur					security.security_pkg.T_OUTPUT_CUR;
BEGIN
	security.user_pkg.LogOnAdmin();
	FOR r IN (
		SELECT DISTINCT w.website_name
		  FROM security.securable_object so
		  JOIN security.website w ON so.application_sid_id = w.application_sid_id	
		 WHERE so.class_id = security.class_pkg.GetClassId('CSRSectionRoot')
		   AND so.parent_sid_id = so.application_sid_id
		   AND so.name != 'Sections'
	)
	LOOP
		-- Log on
		security.user_pkg.LogOnAdmin(r.website_name);
		v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
		v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
		
		dbms_output.put_line('-------------------- Host: ' || r.website_name || ' --------------------');
		
		-- Get indexes root sid
		BEGIN
			security.securableobject_pkg.CreateSO(v_act_id, v_app_sid, security.security_pkg.SO_CONTAINER, 'Indexes', v_indexes_root_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_indexes_root_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Indexes');
		END;
	
		FOR s IN (
			SELECT so.sid_id, so.name
			  FROM security.securable_object so
			 WHERE so.class_id = security.class_pkg.GetClassId('CSRSectionRoot')
			   AND so.parent_sid_id = so.application_sid_id
			   AND so.name != 'Sections'
			   AND so.application_sid_id = v_app_sid
		)
		LOOP
			-- RegisertedUsers: Read on indexes
			v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/RegisteredUsers');
			security.acl_pkg.AddACE(
				v_act_id,
				security.acl_pkg.GetDACLIDForSID(v_indexes_root_sid),
				security.security_pkg.ACL_INDEX_LAST,
				security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT,
				v_reg_users_sid,
				security.security_pkg.PERMISSION_STANDARD_READ
			);

			-- Get current permissions
			security.acl_pkg.GetDACL(v_act_id, s.sid_id, out_cur);
			
			BEGIN
				-- Move SO
				security.securableobject_pkg.MoveSO(v_act_id, s.sid_id, v_indexes_root_sid);
				dbms_output.put_line('Moved SO: ' || s.name || ' (' || s.sid_id || ')');
			EXCEPTION
				WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
					dbms_output.put_line('Skipped SO: ' || s.name || ' (' || s.sid_id || ')');
			END;
			
			-- Clear permissions
			security.acl_pkg.DeleteAllACES(v_act_id, security.acl_pkg.GetDACLIdForSID(s.sid_id));
			
			-- Apply same permissions
			LOOP
				FETCH out_cur INTO v_acl_id, v_acl_index, v_ace_type, v_ace_flags, v_sid_id, v_permission_set;
				EXIT WHEN out_cur%NOTFOUND;
				
				security.acl_pkg.AddACE(v_act_id, v_acl_id, security.security_pkg.ACL_INDEX_LAST, v_ace_type, v_ace_flags, v_sid_id, v_permission_set);
			END LOOP;
		END LOOP; 
		-- Log off
		security.user_pkg.Logoff(v_act_id);
	END LOOP;
END;
/

-- ** New package grants **

-- *** Packages ***
@..\csr_app_body
@..\section_root_body
@..\enable_body

@update_tail
