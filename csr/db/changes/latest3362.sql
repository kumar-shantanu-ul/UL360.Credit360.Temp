define version=3362
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

CREATE TABLE CSR.MANANGED_CONTENT_UNPACKAGE_LOG_RUN (
	APP_SID		NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	MESSAGE_ID 	NUMBER(10, 0) NOT NULL,
	RUN_ID 		NUMBER(10, 0) NOT NULL,
	SEVERITY	VARCHAR2(1) NOT NULL,
	MSG_DTM		DATE NOT NULL,
	MESSAGE		CLOB NOT NULL,
    CONSTRAINT PK_MANGED_CONTENT_UNPKG_LOG_RUN PRIMARY KEY (APP_SID, RUN_ID, MESSAGE_ID),
    CONSTRAINT CK_MANAGED_CONTENT_MSG_SEV CHECK (SEVERITY IN ('E','C','I','D'))
);
CREATE SEQUENCE CSR.MANAGED_CONTENT_UNPACKAGE_MSG_SEQ;
CREATE SEQUENCE CSR.MANAGED_CONTENT_UNPACKAGE_RUN_SEQ;
CREATE OR REPLACE TYPE CSR.T_SHEET_INFO AS
  OBJECT (
	SHEET_ID						NUMBER(10,0),
	DELEGATION_SID					NUMBER(10,0),
	PARENT_DELEGATION_SID			NUMBER(10,0),
	NAME							VARCHAR2(1023),
	CAN_SAVE						NUMBER(10,0),
	CAN_SUBMIT						NUMBER(10,0),
	CAN_ACCEPT						NUMBER(10,0),
	CAN_RETURN						NUMBER(10,0),
	CAN_DELEGATE					NUMBER(10,0),
	CAN_VIEW						NUMBER(10,0),
	CAN_OVERRIDE_DELEGATOR			NUMBER(10,0),
	CAN_COPY_FORWARD				NUMBER(10,0),
	LAST_ACTION_ID					NUMBER(10,0),
	START_DTM						DATE,
	END_DTM							DATE,
	PERIOD_SET_ID					NUMBER(10),
	PERIOD_INTERVAL_ID				NUMBER(10),
	GROUP_BY						VARCHAR2(128),
	NOTE							CLOB,
	USER_LEVEL						NUMBER(10,0),
	IS_TOP_LEVEL					NUMBER(10,0),
	IS_READ_ONLY					NUMBER(1),
	CAN_EXPLAIN						NUMBER(1)
  );
/


alter table csr.temp_delegation_detail modify name varchar2(1023);
alter table csr.temp_delegation_for_region modify name varchar2(1023);










BEGIN
  dbms_scheduler.run_job(
    job_name  => 'CSR.UPDATE_METRIC_VALS',
    use_current_session	=> false
  );
END;
/
DECLARE
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_reg_users_sid					security.security_pkg.T_SID_ID;
	v_www_sid						security.security_pkg.T_SID_ID;
	v_www_csr_site					security.security_pkg.T_SID_ID;
	v_www_helpiq					security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act_id);
	FOR r IN (
		SELECT application_sid_id app_sid, web_root_sid_id, website_name
		  FROM security.website
		 WHERE application_sid_id in (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'Groups');
		v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
		v_www_sid := r.web_root_sid_id; --security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot');
		BEGIN
			v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN 
				dbms_output.put_line(r.website_name||':  *no csr/site for '||r.app_sid);
				CONTINUE;
		END;
		BEGIN
			v_www_helpiq       := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot/csr/site/helpiq.acds');
			--dbms_output.put_line(r.website_name||':  helpiq resource exists for '||r.app_sid);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				dbms_output.put_line(r.website_name||':  creating helpiq for '||r.app_sid);
				security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site, 'helpiq.acds', v_www_helpiq);
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_helpiq), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
					security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		END;
	END LOOP;
END;
/
DECLARE
	v_app_sid		security.security_pkg.T_SID_ID := 0;
	v_act			security.security_pkg.T_ACT_ID;
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
			security.user_pkg.logonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, r.app_sid, v_act);
			v_app_sid := r.app_sid;
			
			BEGIN
				INSERT INTO csr.score_type
				(score_type_id, label, pos, hidden, allow_manual_set, lookup_key, reportable_months, format_mask, applies_to_audits)
				VALUES
				(csr.score_type_id_seq.nextval, 'Score', 1, 0, 0, 'RBA_AUDIT_SCORE', 24, '##0.00', 1)
				RETURNING score_type_id INTO v_score_type_id;
			EXCEPTION
			  WHEN DUP_VAL_ON_INDEX THEN
				SELECT score_type_id
				  INTO v_score_type_id
				  FROM csr.score_type
				 WHERE lookup_key = 'RBA_AUDIT_SCORE';
			END;
		END IF;	
		
		BEGIN
			INSERT INTO csr.score_type_audit_type
			(app_sid, score_type_id, internal_audit_type_id)
			VALUES
			(r.app_sid, v_score_type_id, r.internal_audit_type_id);
		EXCEPTION
			  WHEN DUP_VAL_ON_INDEX THEN NULL;
		END;
	END LOOP;
	security.user_pkg.logonadmin();
END;
/






@..\managed_content_pkg
@..\..\..\aspen2\cms\db\form_pkg


@..\region_metric_body
@..\delegation_body
@..\quick_survey_body
@..\managed_content_body
@..\..\..\aspen2\cms\db\form_body
@..\meter_report_body
@..\chain\company_body
@..\audit_report_body
@..\measure_body
@..\flow_body



@update_tail
