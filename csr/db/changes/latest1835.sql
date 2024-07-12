-- Please update version.sql too -- this keeps clean builds in sync
define version=1835
@update_header

DECLARE
	v_sid		security.security_pkg.T_SID_ID;
BEGIN
	-- Fix any super admin pivot tables
	UPDATE security.securable_object
	   SET application_sid_id = NULL
	 WHERE parent_sid_id IN (select csr_user_sid FROM csr.superadmin)
	   AND name='Pivot tables';
	
	security.user_pkg.LogonAdmin;
	
	-- Pre-create all other super admin pivot tables so to not get restricted by app sid
	FOR r IN (
		SELECT csr_user_sid
		  FROM csr.superadmin
	) LOOP
		BEGIN
			security.securableobject_pkg.CreateSo(security.security_pkg.GetAct, r.csr_user_sid, security.security_pkg.SO_CONTAINER, 'Pivot tables', v_sid);
		EXCEPTION WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN 
			NULL;
		END;
	END LOOP;
END;
/


-- #### CMS Issue column comments start ####

-- Update any existing columns that use Issues
-- that are using an incorrect col_type.
UPDATE cms.tab_column SET col_type = 8
WHERE tab_sid IN (SELECT tab_sid FROM cms.tab WHERE oracle_table='ISSUE' AND oracle_schema='CSR')
AND oracle_column LIKE '%_USER_SID';

-- Add comments to csr.issue so CMS can figure out they
-- are user columns automatically when registering tables.
COMMENT ON COLUMN csr.issue.CLOSED_BY_USER_SID IS 'user';
COMMENT ON COLUMN csr.issue.ASSIGNED_TO_USER_SID IS 'user';
COMMENT ON COLUMN csr.issue.RAISED_BY_USER_SID IS 'user';
COMMENT ON COLUMN csr.issue.RESOLVED_BY_USER_SID IS 'user';
COMMENT ON COLUMN csr.issue.OWNER_USER_SID IS 'user';
COMMENT ON COLUMN csr.issue.REJECTED_BY_USER_SID IS 'user';

-- #### CMS Issue column comments end ####

@..\issue_pkg

@..\issue_body

-- Fetch delete rules with GetTableDefinitions so the REST API can use them

@..\..\..\aspen2\cms\db\tab_pkg
@..\..\..\aspen2\cms\db\tab_body

@update_tail