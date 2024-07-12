-- Please update version.sql too -- this keeps clean builds in sync
define version=2946
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
-- this is a copy of current csr.csr_data_pkg.SetSelfRegistrationPermissions
CREATE OR REPLACE PROCEDURE csr.tmp_SetSelfRegistrationPerms(
	in_setting						IN	NUMBER
)
IS
	v_app_sid				security.security_pkg.T_SID_ID;
	v_act_id				security.security_pkg.T_ACT_ID;
	v_ind_root_sid			security.security_pkg.T_SID_ID;
	v_region_root_sid		security.security_pkg.T_SID_ID;
	v_usercreatordaemon_sid	security.security_pkg.T_SID_ID;
	
	v_ind_acl_id			security.security_pkg.T_SID_ID;
	v_region_acl_id			security.security_pkg.T_SID_ID;
	v_current_ind_perms		security.acl.permission_set%TYPE;
	v_current_region_perms	security.acl.permission_set%TYPE;
	v_current_ind_access	BOOLEAN;
	v_current_region_access	BOOLEAN;
BEGIN
	v_app_sid := security.security_pkg.getApp;
	v_act_id := security.security_pkg.getact;
	
	-- Add/remove UserCreatorDaemon write access from the Indicator and Region roots.
	v_ind_root_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Indicators');
	v_region_root_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Regions');
	BEGIN
		v_usercreatordaemon_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Users/usercreatordaemon');
	EXCEPTION
		 WHEN security.security_pkg.OBJECT_NOT_FOUND THEN RETURN;
	END;

	v_ind_acl_id := security.acl_pkg.GetDACLIDForSID(v_ind_root_sid);
	v_region_acl_id := security.acl_pkg.GetDACLIDForSID(v_region_root_sid);
	
	v_current_ind_perms := 0;
	v_current_region_perms := 0;
	v_current_ind_access := FALSE;
	v_current_region_access := FALSE;
	
	BEGIN
		SELECT MAX(permission_set)
		  INTO v_current_ind_perms
		  FROM security.ACL
		 WHERE acl_id = v_ind_acl_id 
		   AND sid_id = v_usercreatordaemon_sid
		   AND ace_flags = security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE;
	EXCEPTION
		 WHEN NO_DATA_FOUND THEN NULL;
	END;

	BEGIN
		SELECT MAX(permission_set)
		  INTO v_current_region_perms
		  FROM security.ACL
		 WHERE acl_id = v_region_acl_id 
		   AND sid_id = v_usercreatordaemon_sid
		   AND ace_flags = security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE;
	EXCEPTION
		 WHEN NO_DATA_FOUND THEN NULL;
	END;

	IF v_current_ind_perms = security.security_pkg.PERMISSION_STANDARD_READ+security.security_pkg.PERMISSION_WRITE THEN
		v_current_ind_access := TRUE;
	END IF;
	   
	IF v_current_region_perms = security.security_pkg.PERMISSION_STANDARD_READ+security.security_pkg.PERMISSION_WRITE THEN
		v_current_region_access := TRUE;
	END IF;

	IF in_setting = 0 THEN
		IF v_current_ind_access = TRUE THEN
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ind_root_sid), v_usercreatordaemon_sid);
		END IF;
		IF v_current_region_access = TRUE THEN
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_region_root_sid), v_usercreatordaemon_sid);
		END IF;
	ELSE
		IF v_current_ind_access = FALSE THEN
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ind_root_sid), -1, 
				security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, 
				v_usercreatordaemon_sid, security.security_pkg.PERMISSION_STANDARD_READ+security.security_pkg.PERMISSION_WRITE);
		END IF;
		IF v_current_region_access = FALSE THEN
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_region_root_sid), -1, 
				security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, 
				v_usercreatordaemon_sid, security.security_pkg.PERMISSION_STANDARD_READ+security.security_pkg.PERMISSION_WRITE);
		END IF;
	END IF;
END;
/

BEGIN
	security.user_pkg.logonadmin();
	FOR r IN (
		SELECT host
		  FROM csr.customer
		 WHERE property_flow_sid is not null
	) 
	LOOP
		security.user_pkg.logonadmin(r.host);
		csr.tmp_SetSelfRegistrationPerms(1);
	END LOOP;
	security.user_pkg.logonadmin();
END;
/

DROP PROCEDURE csr.tmp_SetSelfRegistrationPerms;


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
