define version=3500
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



DECLARE
	v_check NUMBER(1);
BEGIN
	SELECT COUNT(constraint_name)
	  INTO v_check
	  FROM all_constraints
	 WHERE owner = 'CSR'
	   AND table_name = 'ALERT'
	   AND constraint_name = 'FK_ALERT_CSR_USER';
	IF v_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.ALERT ADD CONSTRAINT FK_ALERT_CSR_USER FOREIGN KEY (APP_SID, TO_USER_SID) REFERENCES CSR.CSR_USER (APP_SID, CSR_USER_SID)';
	END IF;
END;
/


GRANT SELECT, UPDATE, REFERENCES ON cms.tab_column TO csr;








BEGIN
	FOR r IN (
		SELECT cat.app_sid, alt.alert_frame_id
		  FROM csr.customer_alert_type cat
		  JOIN csr.alert_template alt ON cat.app_sid = alt.app_sid
		 WHERE std_alert_type_id = 20 -- csr.csr_data_pkg.ALERT_GENERIC_MAILOUT
	) LOOP
		INSERT INTO csr.alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
		SELECT r.app_sid, cat.customer_alert_type_id, r.alert_frame_id, dat.send_type
		  FROM csr.default_alert_template dat
		  JOIN csr.customer_alert_type cat ON cat.app_sid = r.app_sid AND cat.std_alert_type_id = dat.std_alert_type_id
		 WHERE dat.std_alert_type_id = 80 -- csr.csr_data_pkg.ALERT_SHEET_CREATED
		   AND NOT EXISTS (SELECT NULL FROM csr.alert_template WHERE app_sid = cat.app_sid AND customer_alert_type_id = cat.customer_alert_type_id);
		  
		INSERT INTO csr.alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
		SELECT cat.app_sid, cat.customer_alert_type_id, datb.lang, datb.subject, datb.body_html, datb.item_html
		  FROM csr.default_alert_template_body datb 
		  JOIN csr.customer_alert_type cat ON cat.app_sid = r.app_sid AND cat.std_alert_type_id = datb.std_alert_type_id
		 WHERE datb.std_alert_type_id = 80 -- csr.csr_data_pkg.ALERT_SHEET_CREATED
		   AND NOT EXISTS (SELECT NULL FROM csr.alert_template_body WHERE app_sid = cat.app_sid AND customer_alert_type_id = cat.customer_alert_type_id);
	END LOOP;
END;
/
		 
BEGIN
    DBMS_SCHEDULER.DROP_JOB(job_name => 'OSC.CHECKBSCIMEMBERSHIP');
    DBMS_SCHEDULER.DROP_JOB(job_name => 'OSC.PROCESSCOMPANYEVENTS');
    DBMS_SCHEDULER.DROP_JOB(job_name => 'OSC.SIXMONTHLYREVIEW');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


DECLARE
	v_act_id			security.security_pkg.T_ACT_ID;
	v_www_root			security.security_pkg.T_SID_ID;
	v_groups_sid		security.security_pkg.T_SID_ID;
	v_reg_users_sid		security.security_pkg.T_SID_ID;
	v_www_ui			security.security_pkg.T_SID_ID;
BEGIN
	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website w
		 WHERE application_sid_id IN (
			SELECT app_sid
			  FROM csr.customer
		  )
	)
	LOOP
		security.user_pkg.LogonAuthenticated(
			in_sid_id		=> security.security_pkg.SID_BUILTIN_ADMINISTRATOR,
			in_act_timeout 	=> 172800,
			in_app_sid		=> r.application_sid_id,
			out_act_id		=> v_act_id
		);
		v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'Groups');
		v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
		v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'wwwroot');
		BEGIN			
			-- web resource for the ui
			v_www_ui := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_root, 'ui');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_root, 'ui', v_www_ui);
		END;
		security.acl_pkg.AddACE(
			v_act_id,
			security.acl_pkg.GetDACLIDForSID(v_www_ui),
			-1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_reg_users_sid,
			security.security_pkg.PERMISSION_STANDARD_READ
		);
	END LOOP;
END;
/


@..\issue_pkg
@..\csr_data_pkg
@..\..\..\aspen2\cms\db\tab_pkg
@..\core_access_pkg
@..\unit_test_pkg
@..\doc_body
@..\chain\company_filter_body;
@..\issue_body
@..\deleg_plan_body
@..\automated_export_body
@..\automated_import_body
@..\sheet_body
@..\chain\filter_body
@..\core_access_body
@..\unit_test_body



@update_tail
