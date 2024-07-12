define version=3465
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



ALTER TABLE CSRIMP.QUICK_SURVEY_EXPR_ACTION DROP CONSTRAINT CHK_QS_EXPR_ACTION_TYPE_FK DROP INDEX;
ALTER TABLE CSRIMP.QUICK_SURVEY_EXPR_ACTION ADD CONSTRAINT CHK_QS_EXPR_ACTION_TYPE_FK CHECK (
		(ACTION_TYPE = 'nc' AND QS_EXPR_NON_COMPL_ACTION_ID IS NOT NULL
		  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
		  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NULL
		  AND ISSUE_TEMPLATE_ID IS NULL)
		OR
		(ACTION_TYPE = 'msg' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
		  AND QS_EXPR_MSG_ACTION_ID IS NOT NULL AND SHOW_QUESTION_ID IS NULL
		  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NULL
		  AND ISSUE_TEMPLATE_ID IS NULL)
		OR
		(ACTION_TYPE = 'show_q' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
		  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NOT NULL
		  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NULL
		  AND ISSUE_TEMPLATE_ID IS NULL)
		OR
		(ACTION_TYPE = 'mand_q' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
		  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
		  AND MANDATORY_QUESTION_ID IS NOT NULL AND SHOW_PAGE_ID IS NULL
		  AND ISSUE_TEMPLATE_ID IS NULL)
		OR
		(ACTION_TYPE = 'show_p' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
		  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
		  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NOT NULL
		  AND ISSUE_TEMPLATE_ID IS NULL)
		OR
		(ACTION_TYPE = 'issue' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
		  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
		  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NULL
		  AND ISSUE_TEMPLATE_ID IS NOT NULL)
	);
ALTER TABLE ASPEN2.LANG_DEFAULT_INCLUDE ADD CONSTRAINT FK_APP_LANG_DEF_INC 
    FOREIGN KEY (application_sid)
    REFERENCES ASPEN2.APPLICATION(app_sid)
;
create index aspen2.ix_lang_default__application_s on aspen2.lang_default_include (application_sid);
ALTER TABLE CSR.ISSUE_LOG_FILE ADD ARCHIVE_FILE_ID VARCHAR2(50);
ALTER TABLE CSR.ISSUE_LOG_FILE ADD ARCHIVE_FILE_SIZE NUMBER(10);
ALTER TABLE CSR.ISSUE_LOG_FILE MODIFY SHA1 NULL;
ALTER TABLE CSRIMP.ISSUE_LOG_FILE ADD ARCHIVE_FILE_ID VARCHAR2(50);
ALTER TABLE CSRIMP.ISSUE_LOG_FILE ADD ARCHIVE_FILE_SIZE NUMBER(10);
ALTER TABLE CSRIMP.ISSUE_LOG_FILE MODIFY SHA1 NULL;










DELETE FROM aspen2.translated WHERE application_sid IN (
  SELECT DISTINCT t.application_sid FROM aspen2.translated t
    LEFT JOIN aspen2.application a ON a.app_sid = t.application_sid
    LEFT JOIN csr.customer c ON c.app_sid = t.application_sid
   WHERE c.app_sid IS NULL AND a.app_sid IS NULL
);
DELETE FROM aspen2.translation WHERE application_sid IN (
  SELECT DISTINCT t.application_sid FROM aspen2.translation t
    LEFT JOIN aspen2.application a ON a.app_sid = t.application_sid
    LEFT JOIN csr.customer c ON c.app_sid = t.application_sid
   WHERE c.app_sid IS NULL AND a.app_sid IS NULL
);
DELETE FROM aspen2.translation_set_include WHERE application_sid IN (
  SELECT DISTINCT tsi.application_sid FROM aspen2.translation_set_include tsi
    LEFT JOIN aspen2.application a ON a.app_sid = tsi.application_sid
    LEFT JOIN csr.customer c ON c.app_sid = tsi.application_sid
   WHERE c.app_sid IS NULL AND a.app_sid IS NULL
);
DELETE FROM aspen2.translation_set_include WHERE to_application_sid IN (
  SELECT DISTINCT tsi.to_application_sid FROM aspen2.translation_set_include tsi
    LEFT JOIN aspen2.application a ON a.app_sid = tsi.to_application_sid
    LEFT JOIN csr.customer c ON c.app_sid = tsi.to_application_sid
   WHERE c.app_sid IS NULL AND a.app_sid IS NULL
);
DELETE FROM aspen2.translation_set WHERE application_sid IN (
  SELECT DISTINCT ts.application_sid FROM aspen2.translation_set ts
    LEFT JOIN aspen2.application a ON a.app_sid = ts.application_sid
    LEFT JOIN csr.customer c ON c.app_sid = ts.application_sid
   WHERE c.app_sid IS NULL AND a.app_sid IS NULL
);
DELETE FROM aspen2.translation_application WHERE application_sid IN (
  SELECT DISTINCT ta.application_sid FROM aspen2.translation_application ta
    LEFT JOIN aspen2.application a ON a.app_sid = ta.application_sid
    LEFT JOIN csr.customer c ON c.app_sid = ta.application_sid
   WHERE c.app_sid IS NULL AND a.app_sid IS NULL
);
UPDATE csr.capability 
SET name = 'Prioritise sheet values in sheets'
WHERE name = 'Priortise sheet values in sheets';
INSERT INTO csr.capability (name, allow_by_default, description)
VALUES ('Can manage custom notification templates', 0, 'Allows creation and modification of notification types');
DECLARE
	v_act							security.security_pkg.T_ACT_ID;
	v_resource						security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, NULL, v_act);
	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id IN (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		BEGIN
			security.web_pkg.CreateResource(v_act, r.web_root_sid_id, r.web_root_sid_id, 'api.notifications', v_resource);
			security.acl_pkg.AddACE(
				v_act,
				security.acl_pkg.GetDACLIDForSID(v_resource),
				security.security_pkg.ACL_INDEX_LAST,
				security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT,
				security.securableobject_pkg.getsidfrompath(v_act, r.application_sid_id, 'Groups/RegisteredUsers'),
				security.security_pkg.PERMISSION_STANDARD_READ);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
	END LOOP;
	security.user_pkg.LogOff(v_act);
END;
/






@..\..\..\security\db\oracle\web_pkg
@..\schema_pkg


@..\schema_body
@..\csr_app_body
@..\..\..\security\db\oracle\web_body
@..\chain\company_filter_body
@..\audit_body
@..\enable_body
@..\csrimp\imp_body
@..\issue_body
@..\notification_body
@..\superadmin_api_body
@..\csr_user_body



@update_tail
