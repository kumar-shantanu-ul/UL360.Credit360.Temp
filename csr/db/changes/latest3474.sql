define version=3474
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;

CREATE TABLE csr.failed_notification_archive (
    app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	failed_notification_id			NUMBER(10, 0)	NOT NULL,
	create_dtm						DATE			DEFAULT SYSDATE NOT NULL,
	archive_reason					NUMBER(1)		NOT NULL,
	notification_type_id			VARCHAR2(36)	NOT NULL,
	to_user							VARCHAR2(36)	NOT NULL,
	channel							VARCHAR2(255)	NOT NULL,
	failure_code					VARCHAR2(255)	NOT NULL,
	failure_exception				VARCHAR2(1024),
	failure_detail					VARCHAR2(1024),
	from_user						VARCHAR2(36),
	merge_fields					CLOB,
	repeating_merge_fields			CLOB,
	CONSTRAINT pk_failed_notification_archive PRIMARY KEY (app_sid, failed_notification_id),
	CONSTRAINT ck_archive_reason CHECK (archive_reason IN (0, 1, 2))
);


ALTER TABLE csrimp.application
	 MODIFY BLOCK_SA_LOGON NULL;
UPDATE csrimp.application
   SET BLOCK_SA_LOGON = null;
ALTER TABLE csrimp.application
DROP COLUMN BLOCK_SA_LOGON;
ALTER TABLE csr.failed_notification ADD (
	create_dtm						DATE			DEFAULT SYSDATE NOT NULL,
	action							NUMBER(1)		DEFAULT 0 NOT NULL,
	failure_exception				VARCHAR2(1024),
	failure_detail					VARCHAR2(1024),
	CONSTRAINT ck_action_valid CHECK (action IN (0, 1, 2))
);






UPDATE csr.util_script
   SET util_script_sp = 'TerminatedClientData'
 WHERE util_script_id = 77;




DELETE FROM csr.util_script_param
 WHERE UTIL_SCRIPT_ID = 76;
DELETE FROM csr.util_script_run_log
 WHERE UTIL_SCRIPT_ID = 76;
DELETE FROM csr.util_script
 WHERE UTIL_SCRIPT_ID = 76;
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE)
VALUES (79, 'Enable/Disable audit calculation changes', 'When enabled, calculation changes require a reason for the change to be entered by the user.', 'SetAuditCalcChangesFlag','');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE,PARAM_HIDDEN)
VALUES (79,'Setting value (0 off, 1 on)','The setting to use.',0,null,0);
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE)
VALUES (80, 'Enable/Disable check tolerance against zero', 'When enabled, tolerance violations are triggered when a value changes from zero.', 'SetCheckToleranceAgainstZeroFlag','');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE,PARAM_HIDDEN)
VALUES (80,'Setting value (0 off, 1 on)','The setting to use.',0,null,0);
DECLARE
	v_count		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM security.web_resource
	 WHERE path = '/csr/sasso/login';
	IF v_count = 0 THEN
		-- Superadmin SSO is not configured on this database. Skip
		-- so that we don't disable accounts that may be used for tests
		-- (e.g. on .auto or .sprint) where SA SSO is not available.
		RETURN;
	END IF;
	FOR r IN (
		SELECT csr_user_sid
		  FROM csr.superadmin
		 WHERE LOWER(user_name) NOT LIKE ('%@global.ul.com')
	)
	LOOP
		security.user_pkg.UNSEC_DisableAccount(r.csr_user_sid);
		
		-- Null out password.
		UPDATE security.user_table
		   SET login_password = null,
		       login_password_salt = null,
		       java_login_password = null
		 WHERE sid_id = r.csr_user_sid;
		
		COMMIT;
	END LOOP;
END;
/






@..\util_script_pkg
@..\automated_export_pkg
@..\notification_pkg
@..\flow_pkg
@..\unit_test_pkg


@..\util_script_body
@..\schema_body
@..\enable_body
@..\csrimp\imp_body
@..\automated_export_body
@..\audit_body
@..\csr_app_body
@..\notification_body
@..\delegation_body
@..\flow_body
@..\unit_test_body



@update_tail
