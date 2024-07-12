define version=3411
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



ALTER TABLE ASPEN2.APPLICATION ADD BRANDING_SERVICE_ENABLED NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE ASPEN2.APPLICATION ADD CONSTRAINT CK_BRANDING_SERVICE_ENABLED CHECK (BRANDING_SERVICE_ENABLED IN (0,1,2));
ALTER TABLE CSRIMP.ASPEN2_APPLICATION ADD BRANDING_SERVICE_ENABLED NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.ASPEN2_APPLICATION ADD CONSTRAINT CK_BRANDING_SERVICE_ENABLED CHECK (BRANDING_SERVICE_ENABLED IN (0,1,2));
ALTER TABLE aspen2.application ADD (
	display_cookie_policy NUMBER(1) DEFAULT 1 NOT NULL,
	CONSTRAINT ck_display_cookie_policy CHECK (display_cookie_policy IN (0,1,2))
);
UPDATE aspen2.application a
   SET display_cookie_policy = (SELECT display_cookie_policy FROM csr.customer c WHERE c.app_sid = a.app_sid)
 WHERE a.app_sid IN (SELECT app_sid FROM csr.customer);
   
ALTER TABLE csr.customer DROP COLUMN display_cookie_policy;
ALTER TABLE csrimp.aspen2_application ADD (
	display_cookie_policy NUMBER(1) NULL,
	CONSTRAINT ck_display_cookie_policy CHECK (display_cookie_policy IN (0,1,2))
);
UPDATE csrimp.aspen2_application a
   SET display_cookie_policy = (SELECT display_cookie_policy FROM csrimp.customer c WHERE c.csrimp_session_id = a.csrimp_session_id)
 WHERE a.csrimp_session_id IN (SELECT csrimp_session_id FROM csrimp.customer);

ALTER TABLE csrimp.customer DROP COLUMN display_cookie_policy;
ALTER TABLE csr.customer DROP COLUMN show_feedback_fab;
ALTER TABLE csrimp.customer DROP COLUMN show_feedback_fab;
UPDATE aspen2.application SET branding_service_enabled = 1
WHERE branding_service_css IS NOT NULL;










UPDATE aspen2.application
   SET branding_service_css = REGEXP_REPLACE(LOWER(branding_service_css),'api\.branding.+$', 'api.branding/published-css');
DELETE FROM csr.util_script_run_log WHERE util_script_id IN (71, 72);
DELETE FROM csr.util_script WHERE util_script_id IN (71, 72);






@..\region_pkg
@..\branding_pkg
@..\customer_pkg
@..\util_script_pkg
@..\period_pkg
@..\csr_user_pkg


@..\region_body
@..\..\..\aspen2\db\aspenapp_body
@..\branding_body
@..\schema_body
@..\csrimp\imp_body
@..\customer_body
@..\util_script_body
@..\enable_body
@..\period_body
@..\csr_user_body



@update_tail
