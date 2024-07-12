-- Please update version.sql too -- this keeps clean builds in sync
define version=3433
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DROP TABLE csr.temp_deleg_plan_overlap;

CREATE GLOBAL TEMPORARY TABLE csr.temp_deleg_plan_overlap
(	
	APP_SID						NUMBER(10)  DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	OVERLAPPING_DELEG_SID		NUMBER(10)  NOT NULL,
	APPLIED_TO_REGION_SID		NUMBER(10)  NOT NULL,
	TPL_DELEG_SID				NUMBER(10)  NOT NULL,
	IS_SYNC_DELEG				NUMBER (1)  NOT NULL,
	REGION_SID					NUMBER(10)	NULL,
	DELEG_PLAN_SID				NUMBER(10)  NULL,
	DELEG_PLAN_COL_DELEG_ID		NUMBER(10)  NULL
)
ON COMMIT PRESERVE ROWS;

CREATE TABLE csr.delegation_batch_job_export 
(
	app_sid 					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL, 
	batch_job_id 				NUMBER(10) NOT NULL, 
	file_blob 					BLOB, 
	file_name 					VARCHAR2(1024), 
	CONSTRAINT pk_bj_deleg PRIMARY KEY (app_sid, batch_job_id)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
UPDATE csr.batch_job_type
   SET sp = null,
       plugin_name = 'delegation-plan'
 WHERE batch_job_type_id = 1
 ;

-- RLS

-- Data
	--  Add Web Resource
DECLARE
	v_act_id 					security.security_pkg.T_ACT_ID;
	--
	v_www_root					security.security_pkg.T_SID_ID;
	v_www_resource				security.security_pkg.T_SID_ID;
	v_www_csr_site				security.security_pkg.T_SID_ID;
	v_reg_users_sid				security.security_pkg.T_SID_ID;

BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, v_act_id);

	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id IN (
			SELECT app_sid FROM csr.customer
		 )
	)	 

	LOOP
		BEGIN
			v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'wwwroot/csr/site');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				CONTINUE;
		END;

		BEGIN
			v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'wwwroot');
			v_www_resource := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'batchFileDownload');
			CONTINUE;
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;

		security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_csr_site, 'batchFileDownload', v_www_resource);
		v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'Groups/RegisteredUsers');
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_resource), security.security_pkg.ACL_INDEX_LAST,
								security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
								v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END lOOP;
END;
/

BEGIN
	INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) 
		 VALUES ('Enable Delegation Overlap Warning', 0, 
				 'Delegations: Shows an error message when delegation is overlapped while applying Delegation Plan
				  and while synchronising Child delegations');
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
-- *** Packages ***
@../delegation_pkg
@../deleg_plan_pkg
@../delegation_body
@../deleg_plan_body

@update_tail
