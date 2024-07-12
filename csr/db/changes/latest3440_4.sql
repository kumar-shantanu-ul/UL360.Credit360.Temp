-- Please update version.sql too -- this keeps clean builds in sync
define version=3440
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
-- Make default for new sites.
ALTER TABLE csr.customer
MODIFY enable_java_auth DEFAULT 1;

-- Fix missing CSRIMP column.
ALTER TABLE csrimp.customer
ADD ENABLE_JAVA_AUTH NUMBER(1) NOT NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

DECLARE
	v_superadmin_users_sid		security.security_pkg.T_SID_ID;
	v_app_users_sid				security.security_pkg.T_SID_ID;
BEGIN
	FOR r IN (
		SELECT app_sid, host
		  FROM csr.customer
		 WHERE enable_java_auth = 0
	)
	LOOP
		security.user_pkg.logonAdmin(r.host);
		v_app_users_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, r.app_sid, 'Users');
	
		UPDATE csr.customer
		   SET enable_java_auth = 1
		 WHERE customer.app_sid = r.app_sid;

		-- Apply to users that are directly owned by the site (i.e. exclude super admins, but include trashed users)
		FOR u IN (SELECT cu.csr_user_sid
					FROM csr.csr_user cu
					JOIN security.securable_object so ON so.sid_id = cu.csr_user_sid
			   LEFT JOIN csr.trash t ON t.app_sid = so.application_sid_id AND t.trash_sid = so.sid_id
				   WHERE so.parent_sid_id = v_app_users_sid OR t.previous_parent_sid = v_app_users_sid)
		LOOP
			security.user_pkg.EnableJavaAuth(u.csr_user_sid);
		END LOOP;
		
		COMMIT;
	END LOOP;
	
	security.user_pkg.logonadmin;
	
	-- Migrate SuperAdmins.
	v_superadmin_users_sid := security.securableobject_pkg.GetSidFromPath_(0,'CSR/Users');
	
	FOR s IN (
		SELECT sid_id
		  FROM security.securable_object
		 WHERE parent_sid_id = v_superadmin_users_sid
	)
	LOOP
		security.user_pkg.EnableJavaAuth(s.sid_id);
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csrimp/imp_body
@../schema_body

@update_tail
