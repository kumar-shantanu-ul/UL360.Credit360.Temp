-- Please update version.sql too -- this keeps clean builds in sync
define version=2909
define minor_version=0
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

DECLARE
		v_sa_sid					security.security_pkg.T_SID_ID;
        v_act_id 					security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.logonadmin();
	v_act_id  := security.security_pkg.GetAct;
	v_sa_sid  := security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
  
	FOR r IN (
		SELECT m.action, c.host, c.app_sid, cbr sid_id, security.acl_pkg.GetDACLIDForSID(cbr) acl_id
		  FROM (SELECT so.*, CONNECT_BY_ROOT sid_id cbr FROM security.securable_object so 
				 START WITH so.sid_id IN (SELECT sid_id FROM security.menu WHERE LOWER(action) LIKE '%portlets.acds%' OR LOWER(action) LIKE '%sitelanguages%') 
			   CONNECT BY PRIOR parent_sid_id = sid_id) so
		  JOIN csr.customer c ON so.sid_id = c.app_sid
	JOIN security.menu m ON m.sid_id = so.cbr
	) LOOP	
		-- don't inherit dacls
		security.securableobject_pkg.SetFlags(v_act_id, r.sid_id, 0);
		--Remove inherited ones
		security.acl_pkg.DeleteAllACEs(v_act_id, r.acl_id);
		-- Add Builtin permission
		security.acl_pkg.AddACE(v_act_id, r.acl_id, -1, security.security_pkg.ACE_TYPE_ALLOW, 
		  security.security_pkg.ACE_FLAG_DEFAULT, security.security_pkg.SID_BUILTIN_ADMINISTRATORS, security.security_pkg.PERMISSION_STANDARD_READ);  
		-- Add SA permission
		security.acl_pkg.AddACE(v_act_id, r.acl_id, -1, security.security_pkg.ACE_TYPE_ALLOW, 
		  security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_READ);  		
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
