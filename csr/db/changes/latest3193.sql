define version=3193
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/

-- This took ~15 minutes on UTMDB. Run first to minimise risk of errors.
ALTER TABLE csr.sheet_history ADD (
	is_system_note	NUMBER(1, 0) DEFAULT 0 NOT NULL
);
ALTER TABLE csrimp.sheet_history ADD (
	is_system_note	NUMBER (1, 0) NOT NULL
);

CREATE TABLE CSR.METER_PROCESSING_PIPELINE_INFO (
	APP_SID						NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CONTAINER_ID				VARCHAR2(256)	NOT NULL,
	JOB_ID						VARCHAR2(256)	NOT NULL,
	PIPELINE_ID					VARCHAR2(256)	NULL,
	PIPELINE_STATUS				VARCHAR2(256)	NULL,
	PIPELINE_MESSAGE			VARCHAR2(2048)	NULL,		
	PIPELINE_RUN_START			DATE			NULL,	
	PIPELINE_RUN_END			DATE			NULL,		
	PIPELINE_LAST_UPDATED		DATE			NULL,
	PIPELINE_LA_RUN_ID			VARCHAR2(2048)	NULL,
	PIPELINE_LA_NAME			VARCHAR2(2048)	NULL,	
	PIPELINE_LA_STATUS			VARCHAR2(2048)	NULL,
	PIPELINE_LA_ERRORCODE		VARCHAR2(2048)	NULL,
	PIPELINE_LA_ERRORMESSAGE	VARCHAR2(2048)	NULL,
	PIPELINE_LA_ERRORLOG		CLOB			NULL,	
	CONSTRAINT METER_PROCESSING_PIPELINE_INFO PRIMARY KEY (APP_SID, CONTAINER_ID, JOB_ID)
);
DROP TABLE CSR.METER_PROCESSING_PIPELINE_INFO;
CREATE TABLE CSR.METER_PROCESSING_PIPELINE_INFO (
	APP_SID						NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CONTAINER_ID				VARCHAR2(256)	NOT NULL,
	JOB_ID						VARCHAR2(256)	NOT NULL,
	PIPELINE_ID					VARCHAR2(256)	NULL,
	PIPELINE_STATUS				VARCHAR2(256)	NULL,
	PIPELINE_MESSAGE			VARCHAR2(2048)	NULL,		
	PIPELINE_RUN_START			DATE			NULL,	
	PIPELINE_RUN_END			DATE			NULL,		
	PIPELINE_LAST_UPDATED		DATE			NULL,
	PIPELINE_LA_RUN_ID			VARCHAR2(2048)	NULL,
	PIPELINE_LA_NAME			VARCHAR2(2048)	NULL,	
	PIPELINE_LA_STATUS			VARCHAR2(2048)	NULL,
	PIPELINE_LA_ERRORCODE		VARCHAR2(2048)	NULL,
	PIPELINE_LA_ERRORMESSAGE	VARCHAR2(2048)	NULL,
	PIPELINE_LA_ERRORLOG		CLOB			NULL,	
	CONSTRAINT PK_METER_PROC_PIPELINE_INFO PRIMARY KEY (APP_SID, CONTAINER_ID, JOB_ID)
);


ALTER TABLE CSR.FTP_PROFILE ADD ENABLE_DEBUG_LOG NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.FTP_PROFILE ADD CONSTRAINT CK_FTP_PROFILE_ENABLE_DEBG_LOG CHECK (ENABLE_DEBUG_LOG IN (0, 1)) ENABLE;
ALTER TABLE CSR.FTP_PROFILE ADD CONSTRAINT CK_FTP_PROFILE_PRESV_TIMESTAMP CHECK (PRESERVE_TIMESTAMP IN (0, 1)) ENABLE;
ALTER TABLE csr.user_profile
DROP CONSTRAINT ck_user_profile_gender;
ALTER TABLE csr.user_profile
MODIFY gender VARCHAR2(128);
ALTER TABLE csr.user_profile_staged_record
MODIFY gender VARCHAR2(128);
CREATE OR REPLACE TYPE CSR.T_USER_PROFILE_STAGED_ROW AS 
	OBJECT (
	PRIMARY_KEY						VARCHAR2(256),
	EMPLOYEE_REF					VARCHAR2(128),
	PAYROLL_REF						NUMBER(10),
	FIRST_NAME						VARCHAR2(256),
	LAST_NAME						VARCHAR2(256),
	MIDDLE_NAME						VARCHAR2(256),
	FRIENDLY_NAME					VARCHAR2(256),
	EMAIL_ADDRESS					VARCHAR2(256),
	USERNAME						VARCHAR2(256),
	WORK_PHONE_NUMBER				VARCHAR2(32),
	WORK_PHONE_EXTENSION			VARCHAR2(8),
	HOME_PHONE_NUMBER				VARCHAR2(32),
	MOBILE_PHONE_NUMBER				VARCHAR2(32),
	MANAGER_EMPLOYEE_REF			VARCHAR2(128),
	MANAGER_PAYROLL_REF				NUMBER(10),
	MANAGER_PRIMARY_KEY				VARCHAR2(128),
	EMPLOYMENT_START_DATE			DATE,
	EMPLOYMENT_LEAVE_DATE			DATE,
	PROFILE_ACTIVE					NUMBER(1),
	DATE_OF_BIRTH					DATE,
	GENDER							VARCHAR2(128),
	JOB_TITLE						VARCHAR2(128),
	CONTRACT						VARCHAR2(256),
	EMPLOYMENT_TYPE					VARCHAR2(256),
	PAY_GRADE						VARCHAR2(256),
	BUSINESS_AREA_REF				VARCHAR2(256),
	BUSINESS_AREA_CODE				NUMBER(10),
	BUSINESS_AREA_NAME				VARCHAR2(256),
	BUSINESS_AREA_DESCRIPTION		VARCHAR2(1024),
	DIVISION_REF					VARCHAR2(256),
	DIVISION_CODE					NUMBER(10),
	DIVISION_NAME					VARCHAR2(256),
	DIVISION_DESCRIPTION			VARCHAR2(1024),
	DEPARTMENT						VARCHAR2(256),
	NUMBER_HOURS					NUMBER(12,2),
	COUNTRY							VARCHAR2(128),
	LOCATION						VARCHAR2(256),
	BUILDING						VARCHAR2(256),
	COST_CENTRE_REF					VARCHAR2(256),
	COST_CENTRE_CODE				NUMBER(10),
	COST_CENTRE_NAME				VARCHAR2(256),
	COST_CENTRE_DESCRIPTION			VARCHAR2(1024),
	WORK_ADDRESS_1					VARCHAR2(256),
	WORK_ADDRESS_2					VARCHAR2(256),
	WORK_ADDRESS_3					VARCHAR2(256),
	WORK_ADDRESS_4					VARCHAR2(256),
	HOME_ADDRESS_1					VARCHAR2(256),
	HOME_ADDRESS_2					VARCHAR2(256),
	HOME_ADDRESS_3					VARCHAR2(256),
	HOME_ADDRESS_4					VARCHAR2(256),
	LOCATION_REGION_REF				VARCHAR(1024),
	INTERNAL_USERNAME				VARCHAR2(256),
	MANAGER_USERNAME				VARCHAR2(256),
	ACTIVATE_ON						DATE,
	DEACTIVATE_ON					DATE,
	INSTANCE_STEP_ID				NUMBER(10),
	LAST_UPDATED_DTM				DATE,
	LAST_UPDATED_USER_SID			NUMBER(10),
	LAST_UPDATE_METHOD				VARCHAR(256),
	ERROR_MESSAGE					VARCHAR(1024)
	);
/

DECLARE
	table_doesnt_exist exception;
	pragma exception_init( table_doesnt_exist, -942 );
BEGIN
	--Some blacklist won't let me explicitly drop UPD tables so do it implicitly...
	EXECUTE IMMEDIATE 'DROP TABLE US15446_PROCESSED_DELEGS';
EXCEPTION
	WHEN table_doesnt_exist THEN
		NULL;
END;
/


GRANT EXECUTE ON csr.meter_processing_job_pkg TO web_user;
GRANT EXECUTE ON csr.meter_processing_job_pkg TO web_user;

BEGIN
	INSERT INTO csr.capability (name, allow_by_default, description) VALUES ('Quick chart management', 0, 'Allows user to manage quick chart columns and filters configuration.');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
DECLARE
	v_act_id								security.security_pkg.T_ACT_ID;
	v_app_sid								security.security_pkg.T_SID_ID;
	v_sys_mng_cap_path						VARCHAR2(100) := '/Capabilities/System management';
	v_sys_mng_cap_sid						security.security_pkg.T_SID_ID;
	v_sys_mng_cap_dacl_id					security.securable_object.dacl_id%TYPE;
	v_qck_chrt_cap_path						VARCHAR2(100) := '/Capabilities/Quick chart management';
	v_qck_chrt_cap_sid						security.security_pkg.T_SID_ID;
	v_qck_chrt_cap_dacl_id					security.securable_object.dacl_id%TYPE;
	PROCEDURE EnableCapability(
		in_act_id						IN	security.security_pkg.T_ACT_ID,
		in_app_sid						IN	security.security_pkg.T_SID_ID,
		in_capability  					IN	security.security_pkg.T_SO_NAME
	)
	AS
		v_cap_path							VARCHAR2(100) := '/Capabilities';
		v_allow_by_default					csr.capability.allow_by_default%TYPE;
		v_capability_sid					security.security_pkg.T_SID_ID;
		v_capabilities_sid					security.security_pkg.T_SID_ID;
	BEGIN
		BEGIN
			SELECT allow_by_default
			  INTO v_allow_by_default
			  FROM csr.capability
			 WHERE LOWER(name) = LOWER(in_capability);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20001, 'Unknown capability "'||in_capability||'"');
		END;
		BEGIN
			v_capabilities_sid := security.securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, v_cap_path);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.securableobject_pkg.CreateSO(
					in_act_id				=> in_act_id,
					in_parent_sid			=> in_app_sid,
					in_object_class_id		=> security.security_pkg.SO_CONTAINER,
					in_object_name			=> 'Capabilities',
					out_sid_id				=> v_capabilities_sid
				);
		END;
		BEGIN
			security.securableobject_pkg.CreateSO(
				in_act_id				=> in_act_id,
				in_parent_sid			=> v_capabilities_sid,
				in_object_class_id		=> security.class_pkg.GetClassId('CSRCapability'),
				in_object_name			=> in_capability,
				out_sid_id				=> v_capability_sid
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
	END;
BEGIN
	security.user_pkg.LogOnAdmin;
	FOR r IN (
		SELECT host, app_sid
		  FROM (
			SELECT DISTINCT w.website_name host, c.app_sid,
				   ROW_NUMBER() OVER (PARTITION BY c.app_sid ORDER BY c.app_sid) rn
			  FROM csr.customer c
			  JOIN security.website w ON c.app_sid = w.application_sid_id
		)
		 WHERE rn = 1
	)
	LOOP
		security.user_pkg.LogonAdmin(r.host);
		v_act_id := SYS_CONTEXT('SECURITY','ACT');
		v_app_sid := SYS_CONTEXT('SECURITY','APP');
		BEGIN
			v_sys_mng_cap_sid := security.securableobject_pkg.GetSIDFromPath(
				in_act				=> v_act_id,
				in_parent_sid_id	=> v_app_sid,
				in_path				=> v_sys_mng_cap_path
			);
			v_sys_mng_cap_dacl_id := security.acl_pkg.GetDACLIDForSID(
				in_sid_id		=> v_sys_mng_cap_sid
			);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				CONTINUE;
		END;
		EnableCapability(
			in_act_id		=> v_act_id,
			in_app_sid		=> v_app_sid,
			in_capability	=> 'Quick chart management'
		);
		v_qck_chrt_cap_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, v_qck_chrt_cap_path);
		v_qck_chrt_cap_dacl_id := security.acl_pkg.GetDACLIDForSID(v_qck_chrt_cap_sid);
		security.acl_pkg.DeleteAllACES(
			in_act_id			=> v_act_id,
			in_acl_id			=> v_qck_chrt_cap_dacl_id
		);
		FOR r IN (
			SELECT acl_id, acl_index, ace_type, ace_flags, sid_id, permission_set
			  FROM security.acl
			 WHERE acl_id = v_sys_mng_cap_dacl_id
			 ORDER BY acl_index
		)
		LOOP
			security.acl_pkg.AddACE(
				in_act_id				=> v_act_id,
				in_acl_id				=> v_qck_chrt_cap_dacl_id,
				in_acl_index			=> security.security_pkg.ACL_INDEX_LAST,
				in_ace_type				=> r.ace_type,
				in_ace_flags			=> r.ace_flags,	
				in_sid_id				=> r.sid_id,
				in_permission_set		=> r.permission_set
			);
		END LOOP;
	END LOOP;
END;
/
BEGIN
	BEGIN
		INSERT INTO CSR.AUTOMATED_IMPORT_RESULT (AUTOMATED_IMPORT_RESULT_ID, LABEL) VALUES(0, 'Success');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			null;
	END;
	BEGIN
		INSERT INTO CSR.AUTOMATED_IMPORT_RESULT (AUTOMATED_IMPORT_RESULT_ID, LABEL) VALUES(1, 'Partial success');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			null;
	END;
	BEGIN
		INSERT INTO CSR.AUTOMATED_IMPORT_RESULT (AUTOMATED_IMPORT_RESULT_ID, LABEL) VALUES(2, 'Fail');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			null;
	END;
	BEGIN
		INSERT INTO CSR.AUTOMATED_IMPORT_RESULT (AUTOMATED_IMPORT_RESULT_ID, LABEL) VALUES(3, 'Fail (unexpected error)');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			null;
	END;
	BEGIN
		INSERT INTO CSR.AUTOMATED_IMPORT_RESULT (AUTOMATED_IMPORT_RESULT_ID, LABEL) VALUES(4, 'Not attempted');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			null;
	END;
	BEGIN
		INSERT INTO CSR.AUTOMATED_IMPORT_RESULT (AUTOMATED_IMPORT_RESULT_ID, LABEL) VALUES(5, 'Nothing To Do');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			null;
	END;
END;
/

BEGIN
	FOR r IN (
		SELECT distinct host
		  FROM csr.sheet_history sh
		  JOIN csr.customer c ON sh.app_sid = c.app_sid
		  JOIN security.website w ON c.app_sid = w.application_sid_id
		)
	LOOP
		security.user_pkg.logonadmin(r.host);
		
		UPDATE csr.sheet_history sh
		   SET is_system_note = 1 
		 WHERE note like 'Created'
			OR note like 'Set status according to parent sheet.'
			OR note like 'Automatic submission of this sheet was blocked because there are errors'
			OR note like 'Rollback requested'
			OR note like 'Automatically approved'
			OR note like 'Automatic approval failed: intolerances found'
			OR note like 'Data Change Request automatically approved and form returned to user for editing';
			
		COMMIT;
	END LOOP;
	
	security.user_pkg.logonadmin();
END;
/

UPDATE csr.delegation_role dr
   SET deleg_permission_set = 3
 WHERE dr.delegation_sid = dr.inherited_from_sid
   AND NOT EXISTS (
	SELECT NULL FROM csr.delegation WHERE app_sid = dr.app_sid AND delegation_sid = dr.delegation_sid AND parent_sid = app_sid
	)
   AND NOT EXISTS (
	SELECT NULL FROM security.securable_object so JOIN security.acl ON so.dacl_id = acl.acl_id WHERE so.sid_id = dr.delegation_sid AND acl.sid_id = dr.delegation_sid AND permission_set = 263139
   );

--Delete users and roles from delegation groups
DELETE
  FROM security.group_members gm
 WHERE EXISTS (SELECT NULL FROM csr.delegation WHERE delegation_sid = gm.group_sid_id);

-- Stop delegations being a group
DELETE
  FROM security.group_table gt
 WHERE EXISTS (SELECT NULL FROM csr.delegation WHERE delegation_sid = gt.sid_id);

-- Delete delegation aces from delegations.
DELETE
  FROM security.acl
 WHERE EXISTS (SELECT NULL FROM csr.delegation WHERE delegation_sid = acl.sid_id);

BEGIN
	security.user_pkg.LogonAdmin;
	
	UPDATE csr.customer
	   SET alert_mail_address = 'no-reply@cr360.com'
	 WHERE (LOWER(alert_mail_address) = 'support@credit360.com' OR LOWER(alert_mail_address) = 'support@cr360.com');
	UPDATE csr.std_alert_type
	   SET sent_from = REPLACE(sent_from, 'support@credit360.com', 'no-reply@cr360.com')
	 WHERE sent_from LIKE '%support@credit360.com%';
	 
	UPDATE chain.customer_options
	   SET support_email = 'no-reply@cr360.com'
	 WHERE (LOWER(support_email) = 'support@credit360.com' OR LOWER(support_email) = 'support@cr360.com');
	UPDATE csr.default_alert_frame_body
	   SET html = '<template>'||
		'<table width="700">'||
		'<tbody>'||
		'<tr>'||
		'<td>'||
		'<div style="font-size:9pt;color:#888888;font-family:Arial,Helvetica;border-bottom:4px solid #007987;margin-bottom:20px;padding-bottom:10px;">PURE'||unistr('\2122')||' Platform by UL EHS Sustainability</div>'||
		'<table border="0">'||
		'<tbody>'||
		'<tr>'||
		'<td style="font-family:Verdana,Arial;color:#333333;font-size:10pt;line-height:1.25em;padding-right:10px;">'||
		'<mergefield name="BODY" />'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'<div style="font-family:Arial,Helvetica;font-size:9pt;color:#888888;border-top:4px solid #007987;margin-top:20px;padding-top:10px;padding-bottom:10px;">'||
		'</div>'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'</template>';
END;
/

@..\chain\helper_pkg
@..\chain\company_pkg
@..\automated_export_import_pkg
@..\csr_data_pkg
@..\automated_import_pkg
@..\sheet_pkg
@..\audit_migration_pkg
@..\unit_test_pkg
@..\meter_processing_job_pkg
@..\meter_monitor_pkg

@..\region_body
@..\chain\helper_body
@..\chain\company_body
@..\automated_export_import_body
@..\csr_app_body
@..\chain\filter_body
@..\supplier_body
@..\automated_import_body
@..\auto_approve_body
@..\delegation_body
@..\sheet_body
@..\schema_body
@..\csrimp\imp_body
@..\meter_monitor_body
@..\factor_body
@..\enable_body
@..\saml_body
@..\chain\setup_body
@..\audit_migration_body
@..\unit_test_body
@..\meter_processing_job_body

@update_tail
