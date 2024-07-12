-- Please update version.sql too -- this keeps clean builds in sync
define version=2997
define minor_version=38
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE csr.internal_audit_report_guid (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	guid							VARCHAR2(36) NOT NULL,
	expiry_dtm						DATE NOT NULL,
	document						BLOB NULL,
	filename						VARCHAR2(255) NOT NULL,
	doc_type						VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_audit_report_guid PRIMARY KEY (app_sid, guid)
);

-- Alter tables

ALTER TABLE csr.internal_audit_type_report ADD (
	use_merge_field_guid			NUMBER(1) DEFAULT 0 NOT NULL,
	guid_expiration_days			NUMBER(10) NULL,
	CONSTRAINT chk_use_merge_fld_guid CHECK (use_merge_field_guid IN (0,1)),
	CONSTRAINT chk_has_expiration CHECK (use_merge_field_guid = 0 OR guid_expiration_days IS NOT NULL)
);

ALTER TABLE csrimp.internal_audit_type_report ADD (
	use_merge_field_guid			NUMBER(1) DEFAULT 0 NOT NULL,
	guid_expiration_days			NUMBER(10) NULL
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_app_sid 					security.security_pkg.T_SID_ID;
	v_act_id 					security.security_pkg.T_ACT_ID;
	v_www_sid					security.security_pkg.T_SID_ID;
	v_www_csr_site				security.security_pkg.T_SID_ID;
	v_www_csr_site_audit		security.security_pkg.T_SID_ID;
	v_audit_report_sid 			security.security_pkg.T_SID_ID;
	v_www_csr_site_public_audit security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT DISTINCT c.app_sid, c.host
		  FROM security.securable_object so
		  JOIN csr.customer c ON c.app_sid = so.application_sid_id
		 WHERE so.name = 'Audits'
		   AND so.parent_sid_id = so.application_sid_id
	) LOOP
		security.user_pkg.LogonAdmin(r.host);
		v_act_id := SYS_CONTEXT('SECURITY','ACT');
		v_app_sid := SYS_CONTEXT('SECURITY','APP');
		
		v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
		v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');
		v_www_csr_site_audit := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'audit');

		BEGIN
			v_www_csr_site_public_audit := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site_audit, 'public');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site_audit, 'public', v_www_csr_site_public_audit);
			-- add everyone to public audit report download
			security.acl_pkg.AddACE(
				v_act_id,
				security.acl_pkg.GetDACLIDForSID(v_www_csr_site_public_audit),
				security.security_pkg.ACL_INDEX_LAST,
				security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT,
				security.security_pkg.SID_BUILTIN_EVERYONE,
				security.security_pkg.PERMISSION_STANDARD_READ
			);
		END;
		security.user_pkg.Logoff(v_act_id);
	END LOOP;
END;
/

BEGIN
	DBMS_SCHEDULER.CREATE_JOB (
		job_name => '"CSR"."ProcessExpiredAuditReports"',
		job_type => 'PLSQL_BLOCK',
		job_action => 'begin security.user_pkg.LogonAdmin; audit_pkg.ProcessExpiredPublicReports; security.user_pkg.Logoff(SYS_CONTEXT(''SECURITY'',''ACT'')); end;',
		number_of_arguments => 0,
		start_date => to_timestamp_tz('2008/01/01 04:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval => 'FREQ=DAILY',
		enabled => TRUE,
		auto_drop => FALSE,
		comments => 'Clear out expired public audit reports');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\audit_pkg

@..\audit_body
@..\enable_body
@..\schema_body
@..\csrimp\imp_body

@update_tail
