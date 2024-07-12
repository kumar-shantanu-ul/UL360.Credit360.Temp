define version=3359
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

CREATE TABLE CSR.AUTHENTICATION_SCOPE(
	AUTH_SCOPE_ID 			NUMBER(10, 0) NOT NULL,
	AUTH_SCOPE_NAME 		VARCHAR2(255) NOT NULL,
	AUTH_SCOPE 				VARCHAR2(4000) NOT NULL,
	HIDDEN 					NUMBER(1) NOT NULL,
	CONSTRAINT PK_AUTH_SCOPE PRIMARY KEY (AUTH_SCOPE_ID),
	CONSTRAINT UK_AUTH_SCOPE UNIQUE (AUTH_SCOPE_NAME)
);
INSERT INTO CSR.AUTHENTICATION_SCOPE (AUTH_SCOPE_ID, AUTH_SCOPE_NAME, AUTH_SCOPE, HIDDEN) VALUES (1, 'Legacy',
'https://graph.microsoft.com/offline_access,https://graph.microsoft.com/openid,https://graph.microsoft.com/User.Read,https://graph.microsoft.com/Files.ReadWrite.All,https://graph.microsoft.com/Sites.ReadWrite.All', 1);


ALTER TABLE CSR.EXTERNAL_TARGET_PROFILE ADD (
	STORAGE_ACC_NAME			VARCHAR2(400),
	STORAGE_ACC_CONTAINER		VARCHAR2(400)
);
ALTER TABLE CSR.CREDENTIAL_MANAGEMENT ADD (
	AUTH_SCOPE_ID				NUMBER(10, 0)	DEFAULT 1 NOT NULL
);
ALTER TABLE CSR.CREDENTIAL_MANAGEMENT ADD CONSTRAINT FK_AUTH_SCOPE_ID
	FOREIGN KEY (AUTH_SCOPE_ID)
	REFERENCES CSR.AUTHENTICATION_SCOPE(AUTH_SCOPE_ID);
CREATE INDEX csr.ix_credential_ma_auth_scope_id ON csr.credential_management(auth_scope_id);
ALTER TABLE csr.temp_meter_consumption MODIFY (end_dtm NULL);










INSERT INTO CSR.EXTERNAL_TARGET_PROFILE_TYPE (PROFILE_TYPE_ID, LABEL)
VALUES (3, 'Azure Blob Storage');
INSERT INTO CSR.AUTHENTICATION_SCOPE (AUTH_SCOPE_ID, AUTH_SCOPE_NAME, AUTH_SCOPE, HIDDEN) VALUES (2, 'Sharepoint',
'https://graph.microsoft.com/offline_access,https://graph.microsoft.com/openid,https://graph.microsoft.com/User.Read,https://graph.microsoft.com/Files.ReadWrite', 0);
INSERT INTO CSR.AUTHENTICATION_SCOPE (AUTH_SCOPE_ID, AUTH_SCOPE_NAME, AUTH_SCOPE, HIDDEN) VALUES (3, 'Onedrive',
'https://graph.microsoft.com/offline_access,https://graph.microsoft.com/openid,https://graph.microsoft.com/User.Read,https://graph.microsoft.com/Files.ReadWrite', 0);
INSERT INTO CSR.AUTHENTICATION_SCOPE (AUTH_SCOPE_ID, AUTH_SCOPE_NAME, AUTH_SCOPE, HIDDEN) VALUES (4, 'Azure Storage Account', 'https://storage.azure.com/user_impersonation', 0);
DECLARE
	v_act							security.security_pkg.T_ACT_ID;
	v_regusers_sid					security.security_pkg.T_SID_ID;
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_www_sid						security.security_pkg.T_SID_ID;
	v_www_api						security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT application_sid_id
		  FROM security.securable_object
		 WHERE name = 'Can import std factor set'
	)
	LOOP
		v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'wwwroot');
		BEGIN
			v_www_api := security.securableobject_pkg.GetSidFromPath(v_act, v_www_sid, 'api.emissionfactor');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			BEGIN
				security.security_pkg.SetApp(r.application_sid_id);
				security.web_pkg.CreateResource(v_act, v_www_sid, v_www_sid, 'api.emissionfactor', v_www_api);
				v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act, r.application_sid_id, 'Groups');
				v_regusers_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'RegisteredUsers');
				security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_www_api), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security.security_pkg.PERMISSION_STANDARD_READ);
				security.security_pkg.SetApp(null);
			END;
		END;
		
	END LOOP;
	security.user_pkg.LogOff(v_act);
END;
/
UPDATE CSR.STD_ALERT_TYPE 
   SET SEND_TRIGGER = 
	'A sheet has not been submitted, but it is past the reminder date. Reminder notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day. Only reminder notifications within the last 365 days are considered.'
 WHERE STD_ALERT_TYPE_ID = 5;
 
UPDATE CSR.STD_ALERT_TYPE 
   SET SEND_TRIGGER = 
	'A sheet has not been submitted, but it is past the due date. Overdue notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day. Only overdue notifications within the last 365 days are considered.'
 WHERE STD_ALERT_TYPE_ID = 3;
DECLARE
	v_app_sid		security.security_pkg.T_SID_ID;
	v_score_type_id security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin();
	FOR r IN (
		SELECT app_sid, internal_audit_type_id
		  FROM csr.internal_audit_type
		 WHERE lookup_key IN ('RBA_INITIAL_AUDIT', 'RBA_CLOSURE_AUDIT', 'RBA_PRIORITY_CLOSURE_AUDIT')
		 ORDER BY app_sid
	) LOOP
		IF r.app_sid != v_app_sid THEN 
			security.user_pkg.logonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, r.app_sid, security.security_pkg.GetAct);
			
			INSERT INTO csr.score_type
			(score_type_id, label, pos, hidden, allow_manual_set, lookup_key, reportable_months, format_mask, applies_to_audits)
			VALUES
			(csr.score_type_id_seq.nextval, 'Score', 1, 0, 0, 'RBA_AUDIT_SCORE', 24, '##0.00', 1)
			RETURNING score_type_id INTO v_score_type_id;
		END IF;	
		
		INSERT INTO csr.score_type_audit_type
		(score_type_id, internal_audit_type_id)
		VALUES
		(v_score_type_id, r.internal_audit_type_id);
	END LOOP:
	security.user_pkg.logonadmin();
END;
/






@..\credentials_pkg
@..\target_profile_pkg
@..\delegation_pkg
@..\quick_survey_pkg


@..\automated_export_body
@..\credentials_body
@..\target_profile_body
@..\meter_body
@..\delegation_body
@..\sheet_body
@..\role_body
@..\region_body
@..\audit_body
@..\audit_report_body
@..\enable_body
@..\quick_survey_body



@update_tail
