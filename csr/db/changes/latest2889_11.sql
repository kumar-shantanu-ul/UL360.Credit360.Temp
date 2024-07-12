-- Please update version.sql too -- this keeps clean builds in sync
define version=2889
define minor_version=11
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
	BEGIN
		FOR r IN (
			SELECT c.host, m.sid_id 
			  FROM security.menu m 
			  JOIN security.securable_object so ON m.sid_id = so.sid_id
			  JOIN csr.customer c ON so.application_sid_id = c.app_sid
			 WHERE lower(action) like '%portlets.acds%'
			    OR lower(action) like '%sitelanguages.acds%'
		) LOOP
		
			security.user_pkg.logonadmin(r.host);
		
			DECLARE
				v_act_id 					security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
				v_app_sid 					security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
				v_sa_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');	
			BEGIN				
				-- don't inherit dacls
				security.securableobject_pkg.SetFlags(v_act_id, r.sid_id, 0);
				--Remove inherited ones
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(r.sid_id));
				-- Add SA permission
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(r.sid_id), -1, security.security_pkg.ACE_TYPE_ALLOW, 
					security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			END;
			
			security.user_pkg.logoff(security.security_pkg.GetAct);
			
		END LOOP;
	END;
	/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
