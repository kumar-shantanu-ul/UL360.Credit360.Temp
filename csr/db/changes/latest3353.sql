define version=3353
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



ALTER TABLE CSR.EXTERNAL_TARGET_PROFILE
MODIFY (
	SHAREPOINT_SITE VARCHAR2(400),
	SHAREPOINT_FOLDER VARCHAR2(400)
);
ALTER TABLE CSR.EXTERNAL_TARGET_PROFILE ADD (
  ONEDRIVE_FOLDER VARCHAR2(400)
);


GRANT SELECT, INSERT, UPDATE, DELETE ON cms.form_response_import_options TO csr;
grant delete on chain.reference to CSR;
grant delete on chain.reference_capability to CSR;
grant delete on chain.company_reference to CSR;




GRANT CREATE TABLE TO CSR;
CREATE materialized view csr.meter_param_cache REFRESH FORCE ON DEMAND
START WITH TO_DATE('01-01-2021 00:01:00', 'DD-MM-YYYY HH24:MI:SS') NEXT SYSDATE + 1
AS
	SELECT app_sid, MIN(mld.start_dtm) min_start_date, MAX(mld.start_dtm) max_start_date
	  FROM csr.meter_live_data mld
	 GROUP BY app_sid;
REVOKE CREATE TABLE FROM CSR;




INSERT INTO CSR.EXTERNAL_TARGET_PROFILE_TYPE (PROFILE_TYPE_ID, LABEL)
VALUES (2, 'OneDrive');
INSERT INTO csr.util_script(util_script_id, util_script_name, description, util_script_sp, wiki_article)
VALUES(66, 'Set CMS Forms Importer helper SP', 'Sets/updates the helper package that the CMS Forms Importer integration will call when importing responses from the Forms API.', 'SetCmsFormsImpSP', NULL);
INSERT INTO csr.util_script_param(util_script_id, param_name, param_hint, pos, param_value, param_hidden)
VALUES(66, 'Form ID', 'ID of the Form to set/update helper package', 0, NULL, 0);
INSERT INTO csr.util_script_param(util_script_id, param_name, param_hint, pos, param_value, param_hidden)
VALUES(66, 'Helper SP', 'SP called when importing responses', 1, NULL, 0);
INSERT INTO csr.util_script_param(util_script_id, param_name, param_hint, pos, param_value, param_hidden)
VALUES(66, 'Delete?', 'y/n to delete helper sp record for form', 2, 'n', 0);
DECLARE
	v_issue_log_id			csr.issue_log.issue_log_id%TYPE;
BEGIN
	FOR r IN (
		SELECT issue_id, label, region_sid, due_dtm, host
		  FROM csr.issue i
          JOIN csr.customer c on c.app_sid = i.app_sid
		 WHERE source_url LIKE '/meter%'
		   AND issue_type_id = 20
           AND issue_meter_id IS NULL
	) LOOP
        security.user_pkg.logonadmin(r.host, 60);
		INSERT INTO csr.issue_meter (
			app_sid, issue_meter_id, region_sid, issue_dtm)
		VALUES (
			security.security_pkg.GetAPP, csr.issue_meter_id_seq.NEXTVAL, r.region_sid, r.due_dtm
		);
		UPDATE csr.issue
		   SET issue_meter_id = csr.issue_meter_id_seq.CURRVAL,
			   source_url = NULL
		 WHERE issue_id = r.issue_id;
		 
		csr.issue_pkg.AddLogEntry(security.security_pkg.GetACT, r.issue_id, 1, 'Correct issue_meter_id', null, null, null, v_issue_log_id);
	END LOOP;
END;
/
UPDATE csr.util_script
   SET wiki_article = 'W3737'
 WHERE util_script_id = 66;
INSERT INTO csr.module (module_id, module_name, enable_sp, enable_class, description, license_warning)
VALUES (118, 'RBA Integration', 'EnableRBAIntegration', 'Credit360.Enable.EnableRBAIntegration', 'Enable RBA Integration', 1);	






@..\target_profile_pkg
@..\util_script_pkg
@..\meter_pkg
@..\enable_pkg


@..\automated_export_body
@..\target_profile_body
@..\util_script_body
@..\meter_body
@..\issue_body
@..\meter_report_body
@..\enable_body
@..\region_body



@update_tail
