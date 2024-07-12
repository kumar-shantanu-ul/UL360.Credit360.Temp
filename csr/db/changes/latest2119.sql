-- Please update version.sql too -- this keeps clean builds in sync
define version=2119
@update_header

-- *** DDL ***
CREATE SEQUENCE CHAIN.REVIEW_ALERT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE CHAIN.REVIEW_ALERT(
	APP_SID					NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	REVIEW_ALERT_ID			NUMBER(10, 0)    NOT NULL,
	FROM_COMPANY_SID		NUMBER(10, 0)    NOT NULL,
	FROM_USER_SID			NUMBER(10, 0)    NOT NULL,
	TO_COMPANY_SID			NUMBER(10, 0)    NOT NULL,
	TO_USER_SID				NUMBER(10, 0)    NOT NULL,
	SENT_DTM				TIMESTAMP(6),
	CONSTRAINT PK_REVIEW_ALERT PRIMARY KEY (APP_SID, REVIEW_ALERT_ID)
);

CREATE INDEX CHAIN.IX_REVIEW_ALERT ON CHAIN.REVIEW_ALERT(APP_SID, FROM_COMPANY_SID, TO_COMPANY_SID, SENT_DTM);

ALTER TABLE CHAIN.REVIEW_ALERT ADD CONSTRAINT FK_REVIEW_ALERT_FROM_CPNY
	FOREIGN KEY (APP_SID, FROM_COMPANY_SID) REFERENCES CHAIN.COMPANY (APP_SID, COMPANY_SID);

ALTER TABLE CHAIN.REVIEW_ALERT ADD CONSTRAINT FK_REVIEW_ALERT_TO_CPNY
	FOREIGN KEY (APP_SID, TO_COMPANY_SID) REFERENCES CHAIN.COMPANY (APP_SID, COMPANY_SID);

ALTER TABLE CHAIN.REVIEW_ALERT ADD CONSTRAINT FK_REVIEW_ALERT_FROM_USER
	FOREIGN KEY (APP_SID, FROM_USER_SID) REFERENCES CHAIN.CHAIN_USER (APP_SID, USER_SID);

ALTER TABLE CHAIN.REVIEW_ALERT ADD CONSTRAINT FK_REVIEW_ALERT_TO_USER
	FOREIGN KEY (APP_SID, TO_USER_SID) REFERENCES CHAIN.CHAIN_USER (APP_SID, USER_SID);

CREATE INDEX CHAIN.IX_REVIEW_ALERT_FROM_CPNY ON CHAIN.REVIEW_ALERT (APP_SID, FROM_COMPANY_SID);

CREATE INDEX CHAIN.IX_REVIEW_ALERT_TO_CPNY ON CHAIN.REVIEW_ALERT (APP_SID, TO_COMPANY_SID);

CREATE INDEX CHAIN.IX_REVIEW_ALERT_FROM_USER ON CHAIN.REVIEW_ALERT (APP_SID, FROM_USER_SID);

CREATE INDEX CHAIN.IX_REVIEW_ALERT_TO_USER ON CHAIN.REVIEW_ALERT (APP_SID, TO_USER_SID);

ALTER TABLE CHAIN.COMPANY ADD PARENT_SID NUMBER(10);
CREATE UNIQUE INDEX CHAIN.UK_COMP_PARENT_NAME ON CHAIN.COMPANY (NVL(PARENT_SID, COMPANY_SID), LOWER(NAME));
ALTER TABLE CSRIMP.CHAIN_COMPANY ADD PARENT_SID NUMBER(10);

ALTER TABLE CMS.TAB ADD (
	IS_VIEW NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_TAB_IS_VIEW_0_1 
	CHECK (IS_VIEW IN (0,1))
);

ALTER TABLE CSRIMP.CMS_TAB ADD (
	IS_VIEW NUMBER(1) DEFAULT 0 NOT NULL,
	CHECK (IS_VIEW IN (0,1))
);

ALTER TABLE csr.internal_audit_type ADD (
	send_auditor_expiry_alerts	NUMBER(1)    DEFAULT 1 NOT NULL,
	CONSTRAINT chk_snd_adtr_exp_alert_1_0 CHECK (send_auditor_expiry_alerts IN (1,0))
);

ALTER TABLE csrimp.internal_audit_type ADD (send_auditor_expiry_alerts NUMBER(1));
UPDATE csrimp.internal_audit_type SET send_auditor_expiry_alerts=1;
ALTER TABLE csrimp.internal_audit_type MODIFY send_auditor_expiry_alerts NOT NULL;
ALTER TABLE csrimp.internal_audit_type ADD CONSTRAINT chk_snd_adtr_exp_alert_1_0 CHECK (send_auditor_expiry_alerts IN (1,0));

CREATE TABLE csr.audit_type_expiry_alert_role (
	app_sid					NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	internal_audit_type_id	NUMBER(10, 0)    NOT NULL,
	role_sid				NUMBER(10, 0)    NOT NULL,
	CONSTRAINT pk_adt_typ_exp_alert_role PRIMARY KEY (app_sid, internal_audit_type_id, role_sid),
	CONSTRAINT fk_adt_typ_alrt_rle_adt_typ FOREIGN KEY (app_sid, internal_audit_type_id) REFERENCES csr.internal_audit_type (app_sid, internal_audit_type_id),
	CONSTRAINT fk_adt_typ_alrt_rle_role FOREIGN KEY (app_sid, role_sid) REFERENCES csr.role (app_sid, role_sid)
);

CREATE TABLE csrimp.audit_type_expiry_alert_role (
	csrimp_session_id		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	internal_audit_type_id	NUMBER(10, 0)    NOT NULL,
	role_sid				NUMBER(10, 0)    NOT NULL,
	CONSTRAINT pk_adt_typ_exp_alert_role PRIMARY KEY (csrimp_session_id, internal_audit_type_id, role_sid),
	CONSTRAINT fk_adt_typ_exp_alert_role_is FOREIGN KEY
    	(csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

-- *** Grants ***
grant execute on chain.scheduled_alert_pkg to web_user;
grant insert on csr.audit_type_expiry_alert_role to csrimp;
grant select,insert,update,delete on csrimp.audit_type_expiry_alert_role to web_user;

-- *** Cross schema constraints ***

-- *** Views ***

CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label, 
		   ia.auditor_user_sid, ca.full_name auditor_full_name, sr.submitted_dtm survey_completed, 
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, rt.class_name region_type_class_name, SUBSTR(ia.notes, 1, 50) short_notes,
		   ia.notes full_notes, iat.internal_audit_type_id audit_type_id, iat.label audit_type_label,
		   qs.label survey_label, ia.app_sid, ia.internal_audit_type_id, iat.auditor_role_sid,
		   iat.audit_contact_role_sid, ia.audit_closure_type_id, act.label closure_label, act.icon_image_filename,
		   ia.created_by_user_sid, ia.survey_response_id, ia.created_dtm, ca.email auditor_email,
		   iat.filename as template_filename, iat.assign_issues_to_role, cvru.user_giving_cover_sid cover_auditor_sid,
		   fi.flow_sid, f.label flow_label, ia.flow_item_id, fi.current_state_id, fs.label flow_state_label,
		   iat.summary_survey_sid, sqs.label summary_survey_label, ia.summary_response_id, act.is_failure
	  FROM internal_audit ia
	  LEFT JOIN (
			SELECT auc.app_sid, auc.internal_audit_sid, auc.user_giving_cover_sid,
				   ROW_NUMBER() OVER (PARTITION BY auc.internal_audit_sid ORDER BY LEVEL DESC, uc.start_dtm DESC,  uc.user_cover_id DESC) rn,
				   CONNECT_BY_ROOT auc.user_being_covered_sid user_being_covered_sid
			  FROM audit_user_cover auc
			  JOIN user_cover uc ON auc.user_cover_id = uc.user_cover_id
			 CONNECT BY NOCYCLE PRIOR auc.user_being_covered_sid = auc.user_giving_cover_sid
		) cvru
	    ON ia.internal_audit_sid = cvru.internal_audit_sid
	   AND ia.app_sid = cvru.app_sid AND ia.auditor_user_sid = cvru.user_being_covered_sid
	   AND cvru.rn = 1
	  JOIN csr_user ca ON NVL(cvru.user_giving_cover_sid , ia.auditor_user_sid) = ca.csr_user_sid AND ia.app_sid = ca.app_sid
	  LEFT JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id
	  LEFT JOIN quick_survey qs ON ia.survey_sid = qs.survey_sid AND ia.app_sid = qs.app_sid
	  LEFT JOIN quick_survey sqs ON iat.summary_survey_sid = sqs.survey_sid AND iat.app_sid = sqs.app_sid
	  LEFT JOIN (
			SELECT anc.app_sid, anc.internal_audit_sid, COUNT(DISTINCT anc.non_compliance_id) cnt
			  FROM audit_non_compliance anc
			  JOIN issue_non_compliance inc ON anc.non_compliance_id = inc.non_compliance_id AND anc.app_sid = inc.app_sid
			  JOIN issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id AND inc.app_sid = i.app_sid
			 WHERE i.resolved_dtm IS NULL
			   AND i.rejected_dtm IS NULL
			   AND i.deleted = 0
			 GROUP BY anc.app_sid, anc.internal_audit_sid
			) nc ON ia.internal_audit_sid = nc.internal_audit_sid AND ia.app_sid = nc.app_sid
	  LEFT JOIN v$quick_survey_response sr ON ia.survey_response_id = sr.survey_response_id AND ia.app_sid = sr.app_sid
	  JOIN v$region r ON ia.region_sid = r.region_sid
	  JOIN region_type rt ON r.region_type = rt.region_type
	  LEFT JOIN audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id AND ia.app_sid = act.app_sid
	  LEFT JOIN flow_item fi
	    ON ia.flow_item_id = fi.flow_item_id
	  LEFT JOIN flow_state fs
	    ON fs.flow_state_id = fi.current_state_id
	  LEFT JOIN flow f
	    ON f.flow_sid = fi.flow_sid
	 WHERE ia.deleted = 0;
	 
-- *** Data changes ***
CREATE OR REPLACE VIEW CHAIN.v$company AS
	SELECT c.app_sid, c.company_sid, c.created_dtm, c.name, c.activated_dtm, c.active, c.address_1, 
		   c.address_2, c.address_3, c.address_4, c.town, c.state, c.state_id, c.city, c.city_id, c.postcode, c.country_code, 
		   c.phone, c.fax, c.website, c.deleted, c.details_confirmed, c.stub_registration_guid, 
		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, 
		   c.user_level_messaging, c.sector_id,
		   cou.name country_name, s.description sector_description, c.can_see_all_companies, c.company_type_id,
		   ct.lookup_key company_type_lookup, c.supp_rel_code_label, c.supp_rel_code_label_mand,
		   c.parent_sid, p.name parent_name, p.country_code parent_country_code, pcou.name parent_company_name
	  FROM company c
	  LEFT JOIN v$country cou ON c.country_code = cou.country_code
	  LEFT JOIN sector s ON c.sector_id = s.sector_id AND c.app_sid = s.app_sid
	  LEFT JOIN company_type ct ON c.company_type_id = ct.company_type_id
	  LEFT JOIN company p ON c.parent_sid = p.company_sid AND c.app_sid = p.app_sid
	  LEFT JOIN v$country pcou ON p.country_code = pcou.country_code
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND c.deleted = 0
;

-- RLS
DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
    TYPE T_TABS IS TABLE OF VARCHAR2(30);
    v_list T_TABS;
BEGIN
    v_list := t_tabs(
        'REVIEW_ALERT'
    );
    FOR I IN 1 .. v_list.count
    LOOP
        BEGIN
            DBMS_RLS.ADD_POLICY(
                object_schema   => 'CHAIN',
                object_name     => v_list(i),
                policy_name     => SUBSTR(v_list(i), 1, 23)||'_POLICY',
                function_schema => 'CHAIN',
                policy_function => 'appSidCheck',
                statement_types => 'select, insert, update, delete',
                update_check    => true,
                policy_type     => dbms_rls.context_sensitive );
                DBMS_OUTPUT.PUT_LINE('Policy added to '||v_list(i));
        EXCEPTION
            WHEN POLICY_ALREADY_EXISTS THEN
                DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));
            WHEN FEATURE_NOT_ENABLED THEN
                DBMS_OUTPUT.PUT_LINE('RLS policies not applied for '||v_list(i)||' as feature not enabled');
        END;
    END LOOP;
END;
/

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);
	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
	v_found number;
begin	
	v_list := t_tabs(
		'AUDIT_TYPE_EXPIRY_ALERT_ROLE'
	);

	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
					
					-- verify that the table has an app_sid column (dev helper)
					select count(*) 
					  into v_found
					  from all_tab_columns 
					 where owner = 'CSR' 
					   and table_name = UPPER(v_list(i))
					   and column_name = 'APP_SID';
					
					if v_found = 0 then
						raise_application_error(-20001, 'CSR.'||v_list(i)||' does not have an app_sid column');
					end if;
					
					if v_i = 1 then
						v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
					else
						v_name := SUBSTR(v_list(i), 1, 21)||'_POLICY_'||v_i;
					end if;
					dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => 'CSR',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'CSR',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive );
				    -- dbms_output.put_line('done  '||v_name);
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
					WHEN FEATURE_NOT_ENABLED THEN
						DBMS_OUTPUT.PUT_LINE('RLS policy '||v_name||' not applied as feature not enabled');
						exit;
				end;
			end loop;
		end;
	end loop;
end;
/

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
	TYPE T_TABS IS TABLE OF VARCHAR2(30);
	v_list T_TABS;
BEGIN
	v_list := t_tabs(
		'AUDIT_TYPE_EXPIRY_ALERT_ROLE'
	);
	FOR I IN 1 .. v_list.count
	LOOP		
		-- CSRIMP RLS
		BEGIN
			DBMS_RLS.ADD_POLICY(
				object_schema   => 'CSRIMP',
				object_name     => v_list(i),
				policy_name     => SUBSTR(v_list(i), 1, 26)||'_POL',
				function_schema => 'CSRIMP',
				policy_function => 'SessionIDCheck',
				statement_types => 'select, insert, update, delete',
				update_check    => true,
				policy_type     => dbms_rls.context_sensitive );
				DBMS_OUTPUT.PUT_LINE('Policy added to '||v_list(i));
		EXCEPTION
			WHEN POLICY_ALREADY_EXISTS THEN
				DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));
			WHEN FEATURE_NOT_ENABLED THEN
				DBMS_OUTPUT.PUT_LINE('RLS policies not applied for '||v_list(i)||' as feature not enabled');
		END;
	END LOOP;
END;
/

BEGIN
	-- Chain supplier review
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from) VALUES (5021,
		'Chain supplier review',
		'Sent on a scheduled basis for suppliers to review their data.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Chain supplier review',
				send_trigger = 'Sent on a scheduled basis for suppliers to review their data.',
				sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5021;
	END;
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5021, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5021, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5021, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5021, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5021, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5021, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5021, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5021, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5021, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 9);
END;
/

-- Copy audit role into role expiry alert table to keep old behaviour consistent
BEGIN
	FOR r IN (
		SELECT app_sid, internal_audit_type_id, auditor_role_sid
		  FROM csr.internal_audit_type
		 WHERE auditor_role_sid IS NOT NULL
	) LOOP
		INSERT INTO csr.audit_type_expiry_alert_role (app_sid, internal_audit_type_id, role_sid)
		     VALUES (r.app_sid, r.internal_audit_type_id, r.auditor_role_sid);
	END LOOP;
END;
/

-- *** New package grants **

-- *** Packages ***
@..\flow_pkg
@..\audit_pkg
@..\supplier_pkg
@..\schema_pkg
@..\chain\audit_request_pkg
@..\chain\scheduled_alert_pkg
@..\chain\company_pkg
@..\chain\chain_link_pkg
@..\chain\setup_pkg

@..\flow_body
@..\audit_body
@..\supplier_body
@..\tag_body
@..\schema_body
@..\role_body
@..\csr_data_body
@..\chain\audit_request_body
@..\chain\scheduled_alert_body
@..\chain\chain_link_body
@..\chain\supplier_flow_body
@..\chain\company_body
@..\chain\helper_body
@..\chain\setup_body
@..\csrimp\imp_body
@..\..\..\aspen2\cms\db\tab_body

@update_tail
