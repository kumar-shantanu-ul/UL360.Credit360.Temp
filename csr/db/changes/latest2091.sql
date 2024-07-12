-- Please update version.sql too -- this keeps clean builds in sync
define version=2091
@update_header

-- *** DDL ***
-- Create tables

CREATE SEQUENCE CHAIN.AUDIT_REQUEST_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE CHAIN.AUDIT_REQUEST';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/

CREATE TABLE CHAIN.AUDIT_REQUEST (
    APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	AUDIT_REQUEST_ID			NUMBER(10, 0)	NOT NULL,
	AUDITOR_COMPANY_SID			NUMBER(10, 0)	NOT NULL,
	AUDITEE_COMPANY_SID			NUMBER(10, 0)	NOT NULL,
	REQUESTED_BY_COMPANY_SID	NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') NOT NULL,
	REQUESTED_BY_USER_SID		NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
	REQUESTED_AT_DTM			DATE			DEFAULT SYSDATE NOT NULL,
	NOTES						CLOB,
	PROPOSED_DTM				DATE,
	AUDIT_SID					NUMBER(10, 0),
	CONSTRAINT PK_AUDIT_REQUEST PRIMARY KEY (APP_SID, AUDIT_REQUEST_ID),
	CONSTRAINT FK_AUDITREQ_AUDITOR FOREIGN KEY (APP_SID, AUDITOR_COMPANY_SID) REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID),
	CONSTRAINT FK_AUDITREQ_AUDITEE FOREIGN KEY (APP_SID, AUDITEE_COMPANY_SID) REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID),
	CONSTRAINT FK_AUDITREQ_REQBY   FOREIGN KEY (APP_SID, REQUESTED_BY_COMPANY_SID) REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID)
);

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE CHAIN.AUDIT_REQUEST_ALERT';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/

CREATE TABLE CHAIN.AUDIT_REQUEST_ALERT (
    APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	AUDIT_REQUEST_ID			NUMBER(10, 0)	NOT NULL,
	USER_SID					NUMBER(10, 0)	NOT NULL,
	SENT_DTM					DATE,
	CONSTRAINT PK_AUDIT_REQUEST_ALERT PRIMARY KEY (APP_SID, AUDIT_REQUEST_ID, USER_SID),
	CONSTRAINT FK_ADUITREQALERT_AUDITREQ FOREIGN KEY (APP_SID, AUDIT_REQUEST_ID) REFERENCES CHAIN.AUDIT_REQUEST(APP_SID, AUDIT_REQUEST_ID)
);




-- Alter tables
ALTER TABLE csr.audit_closure_type ADD (
	is_failure					NUMBER(1)	DEFAULT 0 NOT NULL,
	CONSTRAINT chk_adt_clsre_typ_is_fail_1_0 CHECK (is_failure IN (1, 0))
);

ALTER TABLE csrimp.audit_closure_type ADD (is_failure NUMBER(1));
UPDATE csrimp.audit_closure_type SET is_failure=0;
ALTER TABLE csrimp.audit_closure_type MODIFY is_failure NOT NULL;
ALTER TABLE csrimp.audit_closure_type ADD (CONSTRAINT chk_adt_clsre_typ_is_fail_1_0 CHECK (is_failure IN (1, 0)));

ALTER TABLE chain.message ADD (
	RE_AUDIT_REQUEST_ID			NUMBER(10, 0),
	CONSTRAINT FK_MESSAGE_AUDITREQ FOREIGN KEY (APP_SID, RE_AUDIT_REQUEST_ID) REFERENCES CHAIN.AUDIT_REQUEST(APP_SID, AUDIT_REQUEST_ID)
);


ALTER TABLE chain.tt_message_search ADD (
	RE_AUDIT_REQUEST_ID			NUMBER(10, 0)
);

ALTER TABLE csr.internal_audit ADD (
	expired						NUMBER(1)	DEFAULT 0 NOT NULL
	CONSTRAINT chk_ia_expired_1_0 CHECK (expired IN (1, 0))
);

ALTER TABLE csrimp.internal_audit ADD (expired NUMBER(1));
UPDATE csrimp.internal_audit SET expired=0;
ALTER TABLE csrimp.internal_audit MODIFY expired NOT NULL;
ALTER TABLE csrimp.internal_audit ADD (CONSTRAINT chk_ia_expired_1_0 CHECK (expired IN (1, 0)));

-- *** Grants ***
grant select on csr.v$flow_item_transition to chain;
grant select on csr.flow_state_transition_inv to chain;
grant select on csr.flow_state_transition_role to chain;
grant select, references on csr.internal_audit to chain;
grant select on csr.flow_capability to chain;
grant select on csr.flow_state_role_capability to chain;
grant select on csr.audit_closure_type to chain;
grant select, insert, delete on csr.customer_flow_alert_class to chain;

-- ** Cross schema constraints ***

ALTER TABLE CHAIN.AUDIT_REQUEST ADD CONSTRAINT REF_AUDITREQ_REQUSER
    FOREIGN KEY (APP_SID, REQUESTED_BY_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID);

ALTER TABLE CHAIN.AUDIT_REQUEST ADD CONSTRAINT REF_AUDITREQ_AUDIT
    FOREIGN KEY (APP_SID, AUDIT_SID)
    REFERENCES CSR.INTERNAL_AUDIT(APP_SID, INTERNAL_AUDIT_SID);

ALTER TABLE CHAIN.AUDIT_REQUEST_ALERT ADD CONSTRAINT REF_AUDITREQALERT_USER
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID);

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
		   ia.flow_item_id, fi.current_state_id, fs.label flow_state_label, iat.summary_survey_sid, 
		   ia.summary_response_id, act.is_failure
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
	  LEFT JOIN (
			SELECT anc.app_sid, anc.internal_audit_sid, COUNT(DISTINCT anc.non_compliance_id) cnt
			  FROM audit_non_compliance anc
			  JOIN issue_non_compliance inc ON anc.non_compliance_id = inc.non_compliance_id AND anc.app_sid = inc.app_sid
			  JOIN issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id AND inc.app_sid = i.app_sid
			 WHERE i.resolved_dtm IS NULL
			   AND i.rejected_dtm IS NULL
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
	 WHERE ia.deleted = 0;

CREATE OR REPLACE VIEW csr.v$audit_next_due AS
	SELECT ia.internal_audit_sid, ia.internal_audit_type_id, ia.region_sid,
		   ia.audit_dtm previous_audit_dtm, act.audit_closure_type_id, ia.app_sid,
		   CASE (re_audit_due_after_type)
				WHEN 'd' THEN ia.audit_dtm + re_audit_due_after
				WHEN 'w' THEN ia.audit_dtm + (re_audit_due_after*7)
				WHEN 'm' THEN ADD_MONTHS(ia.audit_dtm, re_audit_due_after)
				WHEN 'y' THEN ADD_MONTHS(ia.audit_dtm, re_audit_due_after*12)
		   END next_audit_due_dtm, act.reminder_offset_days, act.label closure_label,
		   act.is_failure, ia.label previous_audit_label, act.icon_image_filename,
		   ia.auditor_user_sid previous_auditor_user_sid, ia.flow_item_id
	  FROM (
		SELECT internal_audit_sid, internal_audit_type_id, region_sid, audit_dtm,
			   ROW_NUMBER() OVER (
					PARTITION BY internal_audit_type_id, region_sid
					ORDER BY audit_dtm DESC) rn, -- take most recent audit of each type/region
			   audit_closure_type_id, app_sid, label, auditor_user_sid, flow_item_id, deleted
		  FROM internal_audit
	       ) ia
	  JOIN audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id
	   AND ia.app_sid = act.app_sid
	  JOIN region r ON ia.region_sid = r.region_sid AND ia.app_sid = r.app_sid
	 WHERE rn = 1
	   AND act.re_audit_due_after IS NOT NULL
	   AND r.active=1
	   AND ia.audit_closure_type_id IS NOT NULL
	   AND ia.deleted = 0;
	 
 CREATE OR REPLACE VIEW CHAIN.V$AUDIT_REQUEST AS
	SELECT ar.app_sid,
		   ar.audit_request_id,
		   ar.auditor_company_sid,
		   cor.name auditor_company_name,
		   ar.auditee_company_sid,
		   cee.name auditee_company_name,
		   ar.requested_by_company_sid,
		   crq.name requested_by_company_name,
		   ar.requested_by_user_sid,
		   cu.full_name requested_by_user_full_name,
		   cu.friendly_name req_by_user_friendly_name,
		   cu.email requested_by_user_email,
		   ar.requested_at_dtm,
		   ar.notes,
		   ar.proposed_dtm,
		   ar.audit_sid,
		   ia.label audit_label,
		   ia.audit_dtm,
		   ia.audit_closure_type_id,
		   act.label audit_closure_type_label
	  FROM chain.audit_request ar
	  JOIN chain.company cor ON cor.company_sid = ar.auditor_company_sid AND cor.app_sid = ar.app_sid
	  JOIN chain.company cee ON cee.company_sid = ar.auditee_company_sid AND cee.app_sid = ar.app_sid
	  JOIN chain.company crq ON crq.company_sid = ar.requested_by_company_sid AND crq.app_sid = ar.app_sid
	  JOIN csr.csr_user cu ON cu.csr_user_sid = ar.requested_by_user_sid AND cu.app_sid = ar.app_sid
	  LEFT JOIN csr.internal_audit ia ON ia.internal_audit_sid = ar.audit_sid AND ia.app_sid = ar.app_sid
	  LEFT JOIN csr.audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id AND act.app_sid = ia.app_sid;

CREATE OR REPLACE VIEW CHAIN.v$message AS
	SELECT m.app_sid, m.message_id, m.message_definition_id, 
			m.re_company_sid, m.re_secondary_company_sid, m.re_user_sid,
			m.re_questionnaire_type_id, m.re_component_id, m.re_invitation_id, m.re_audit_request_id,
			m.due_dtm, m.completed_dtm, m.completed_by_user_sid,
			mrl0.refresh_dtm created_dtm, mrl.refresh_dtm last_refreshed_dtm, mrl.refresh_user_sid last_refreshed_by_user_sid
	  FROM message m, message_refresh_log mrl0, message_refresh_log mrl,
		(
			SELECT message_id, MAX(refresh_index) max_refresh_index
			  FROM message_refresh_log 
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 GROUP BY message_id
		) mlr
	 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND m.app_sid = mrl0.app_sid
	   AND m.app_sid = mrl.app_sid
	   AND m.message_id = mrl0.message_id
	   AND m.message_id = mrl.message_id
	   AND mrl0.refresh_index = 0
	   AND mlr.message_id = mrl.message_id
	   AND mlr.max_refresh_index = mrl.refresh_index
;


CREATE OR REPLACE VIEW CHAIN.v$message_recipient AS
	SELECT m.app_sid, m.message_id, m.message_definition_id, 
			m.re_company_sid, m.re_secondary_company_sid, m.re_invitation_id,
			m.re_user_sid, m.re_questionnaire_type_id, m.re_component_id, 
			m.re_audit_request_id, m.completed_dtm, m.completed_by_user_sid,
			r.recipient_id, r.to_company_sid, r.to_user_sid, 
			mrl.refresh_dtm last_refreshed_dtm, mrl.refresh_user_sid last_refreshed_by_user_sid
	  FROM message_recipient mr, message m, recipient r, message_refresh_log mrl,
		(
			SELECT message_id, MAX(refresh_index) max_refresh_index
			  FROM message_refresh_log 
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 GROUP BY message_id
		) mlr
	 WHERE mr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND mr.app_sid = m.app_sid
	   AND mr.app_sid = r.app_sid
	   AND mr.app_sid = mrl.app_sid
	   AND mr.message_id = m.message_id
	   AND mr.message_id = mrl.message_id
	   AND mr.recipient_id = r.recipient_id
	   AND mlr.message_id = mrl.message_id
	   AND mlr.max_refresh_index = mrl.refresh_index
;


-- *** Data changes ***
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
        'AUDIT_REQUEST', 'AUDIT_REQUEST_ALERT'
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

-- Data

BEGIN
	BEGIN
		INSERT INTO CSR.FLOW_ALERT_CLASS (FLOW_ALERT_CLASS, LABEL) VALUES ('supplier', 'Supply chain');
	EXCEPTION WHEN dup_val_on_index THEN
		NULL; -- some environments have this already?
	END;
END;
/

CREATE OR REPLACE PACKAGE CHAIN.temp_message_pkg
IS
	PROCEDURE DefineMessage (
		in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
		in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
		in_message_template			IN  message_definition.message_template%TYPE,
		in_repeat_type				IN  chain_pkg.T_REPEAT_TYPE 					DEFAULT chain_pkg.ALWAYS_REPEAT,
		in_priority					IN  chain_pkg.T_PRIORITY_TYPE 					DEFAULT chain_pkg.NEUTRAL,
		in_addressing_type			IN  chain_pkg.T_ADDRESS_TYPE 					DEFAULT chain_pkg.COMPANY_USER_ADDRESS,
		in_completion_type			IN  chain_pkg.T_COMPLETION_TYPE 				DEFAULT chain_pkg.NO_COMPLETION,
		in_completed_template		IN  message_definition.completed_template%TYPE 	DEFAULT NULL,
		in_helper_pkg				IN  message_definition.helper_pkg%TYPE 			DEFAULT NULL,
		in_css_class				IN  message_definition.css_class%TYPE 			DEFAULT NULL
	);

	PROCEDURE DefineMessageParam (
		in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
		in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
		in_param_name				IN  message_param.param_name%TYPE,
		in_css_class				IN  message_param.css_class%TYPE 				DEFAULT NULL,
		in_href						IN  message_param.href%TYPE 					DEFAULT NULL,
		in_value					IN  message_param.value%TYPE 					DEFAULT NULL	
	);
	
	PROCEDURE CreateDefaultMessageParam (
		in_message_definition_id	IN  message_definition.message_definition_id%TYPE,
		in_param_name				IN  message_param.param_name%TYPE
	);

	FUNCTION Lookup (
		in_primary_lookup			IN chain_pkg.T_MESSAGE_DEFINITION_LOOKUP
	) RETURN message_definition.message_definition_id%TYPE;

	FUNCTION Lookup (
		in_primary_lookup			IN chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
		in_secondary_lookup			IN chain_pkg.T_MESSAGE_DEFINITION_LOOKUP
	) RETURN message_definition.message_definition_id%TYPE;
END;
/

CREATE OR REPLACE PACKAGE BODY CHAIN.temp_message_pkg
IS
	PROCEDURE DefineMessage (
		in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
		in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
		in_message_template			IN  message_definition.message_template%TYPE,
		in_repeat_type				IN  chain_pkg.T_REPEAT_TYPE 					DEFAULT chain_pkg.ALWAYS_REPEAT,
		in_priority					IN  chain_pkg.T_PRIORITY_TYPE 					DEFAULT chain_pkg.NEUTRAL,
		in_addressing_type			IN  chain_pkg.T_ADDRESS_TYPE 					DEFAULT chain_pkg.COMPANY_USER_ADDRESS,
		in_completion_type			IN  chain_pkg.T_COMPLETION_TYPE 				DEFAULT chain_pkg.NO_COMPLETION,
		in_completed_template		IN  message_definition.completed_template%TYPE 	DEFAULT NULL,
		in_helper_pkg				IN  message_definition.helper_pkg%TYPE 			DEFAULT NULL,
		in_css_class				IN  message_definition.css_class%TYPE 			DEFAULT NULL
	)
	AS
		v_dfn_id					message_definition.message_definition_id%TYPE;
	BEGIN
		IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DefineMessage can only be run as BuiltIn/Administrator');
		END IF;

		BEGIN
			INSERT INTO message_definition_lookup
			(message_definition_id, primary_lookup_id, secondary_lookup_id)
			VALUES
			(message_definition_id_seq.nextval, in_primary_lookup, in_secondary_lookup)
			RETURNING message_definition_id INTO v_dfn_id;
		EXCEPTION 
			WHEN DUP_VAL_ON_INDEX THEN
				v_dfn_id := Lookup(in_primary_lookup, in_secondary_lookup);
		END;
	
		BEGIN
			INSERT INTO default_message_definition
			(message_definition_id, message_template, message_priority_id, repeat_type_id, addressing_type_id, completion_type_id, completed_template, helper_pkg, css_class)
			VALUES
			(v_dfn_id, in_message_template, in_priority, in_repeat_type, in_addressing_type, in_completion_type, in_completed_template, in_helper_pkg, in_css_class);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE default_message_definition
				   SET message_template = in_message_template, 
					   message_priority_id = in_priority, 
					   repeat_type_id = in_repeat_type, 
					   addressing_type_id = in_addressing_type, 
					   completion_type_id = in_completion_type, 
					   completed_template = in_completed_template, 
					   helper_pkg = in_helper_pkg,
					   css_class = in_css_class
				 WHERE message_definition_id = v_dfn_id;
		END;
	END;

	PROCEDURE DefineMessageParam (
		in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
		in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
		in_param_name				IN  message_param.param_name%TYPE,
		in_css_class				IN  message_param.css_class%TYPE DEFAULT NULL,
		in_href						IN  message_param.href%TYPE DEFAULT NULL,
		in_value					IN  message_param.value%TYPE DEFAULT NULL	
	)
	AS
		v_dfn_id					message_definition.message_definition_id%TYPE DEFAULT Lookup(in_primary_lookup, in_secondary_lookup);
	BEGIN
		IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DefineMessageParam can only be run as BuiltIn/Administrator');
		END IF;
	
		CreateDefaultMessageParam(v_dfn_id, in_param_name);
	
		UPDATE default_message_param
		   SET value = in_value, 
			   href = in_href, 
			   css_class = in_css_class
		 WHERE message_definition_id = v_dfn_id
		   AND param_name = in_param_name;
	END;

	PROCEDURE CreateDefaultMessageParam (
		in_message_definition_id	IN  message_definition.message_definition_id%TYPE,
		in_param_name				IN  message_param.param_name%TYPE
	)
	AS
	BEGIN
		BEGIN
			INSERT INTO default_message_param
			(message_definition_id, param_name, lower_param_name)
			VALUES
			(in_message_definition_id, in_param_name, LOWER(in_param_name));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;	
	END;

	FUNCTION Lookup (
		in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP
	) RETURN message_definition.message_definition_id%TYPE
	AS
	BEGIN
		RETURN Lookup(in_primary_lookup, chain_pkg.NONE_IMPLIED);
	END;

	FUNCTION Lookup (
		in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
		in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP
	) RETURN message_definition.message_definition_id%TYPE
	AS
		v_dfn_id					message_definition.message_definition_id%TYPE;
	BEGIN
		SELECT message_definition_id
		  INTO v_dfn_id
		  FROM message_definition_lookup
		 WHERE primary_lookup_id = in_primary_lookup
		   AND secondary_lookup_id = in_secondary_lookup;
	
		RETURN v_dfn_id;
	END;
END;
/

BEGIN
	security.user_pkg.logonadmin;

	BEGIN
		chain.temp_message_pkg.DefineMessage(
			in_primary_lookup 			=> 600, -- chain.chain_pkg.AUDIT_REQUEST_CREATED,
			in_message_template 		=> 'Audit of {reSecondaryCompany} requested by {reUser} at {reCompany}. {reAuditRequestLink}',
			in_completed_template 		=> 'Audit created by {completedByUserFullName} {relCompletedDtm}',
			in_css_class 				=> 'background-icon audit-request-icon',
			in_repeat_type 				=> chain.chain_pkg.ALWAYS_REPEAT,
			in_addressing_type 			=> chain.chain_pkg.COMPANY_ADDRESS,
			in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
			in_priority					=> chain.chain_pkg.NEUTRAL
		);
	EXCEPTION
		WHEN dup_val_on_index THEN NULL;
	END;
	
	BEGIN
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> 600, -- chain.chain_pkg.AUDIT_REQUEST_CREATED, 
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);
	EXCEPTION
		WHEN dup_val_on_index THEN NULL;
	END;
	
	BEGIN
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> 600, -- chain.chain_pkg.AUDIT_REQUEST_CREATED, 
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_value 					=> '{reCompanyName}'
			);
	EXCEPTION
		WHEN dup_val_on_index THEN NULL;
	END;
	
	BEGIN
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> 600, -- chain.chain_pkg.AUDIT_REQUEST_CREATED, 
				in_param_name 				=> 'reSecondaryCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_value 					=> '{reSecondaryCompanyName}'
			);
	EXCEPTION
		WHEN dup_val_on_index THEN NULL;
	END;
	
	BEGIN
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> 600, -- chain.chain_pkg.AUDIT_REQUEST_CREATED, 
				in_param_name 				=> 'reAuditRequestLink', 
				in_value 					=> 'Click here to view the request.',
				in_href						=> '/csr/site/chain/auditRequest.acds?auditRequestId={reAuditRequestId}'
			);
	EXCEPTION
		WHEN dup_val_on_index THEN NULL;
	END;
END;
/

BEGIN
	security.user_pkg.logonadmin;
	BEGIN
	  chain.temp_message_pkg.DefineMessage(
			in_primary_lookup 			=> 103, --chain.chain_pkg.SUPPLIER_DETAILS_REQUIRED
			in_message_template 		=> 'One or more of your {reSuppliers} need updating.',
			in_repeat_type 				=> chain.chain_pkg.REFRESH_OR_REPEAT,
			in_addressing_type 			=> chain.chain_pkg.COMPANY_ADDRESS,
			in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
			in_completed_template 		=> 'Confirmed by {completedByUserFullName} {relCompletedDtm}',
			in_css_class 				=> 'background-icon info-icon',
		in_priority					=> chain.chain_pkg.NEUTRAL
		);
	EXCEPTION
		WHEN dup_val_on_index THEN NULL;
	END;	
	
	BEGIN
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> 103, 
				in_param_name 				=> 'reSuppliers', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_href 					=> '/csr/site/chain/manageCompany/managecompany.acds', 
				in_value 					=> 'suppliers'
			);
	EXCEPTION
		WHEN dup_val_on_index THEN NULL;
	END;
END;
/

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (5020, 'Chain audit request',
	'An audit has been requested.',
	'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
);

DELETE FROM csr.std_alert_type_param WHERE std_alert_type_id = 5020;
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5020, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5020, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5020, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5020, 0, 'AUDITOR_COMPANY_NAME', 'Auditor company name', 'The name of the auditor company', 4);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5020, 0, 'AUDITEE_COMPANY_NAME', 'Auditee company name', 'The name of the auditee company', 5);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5020, 0, 'REQUESTED_BY_COMPANY_NAME', 'Requested by company name', 'The name of the company requesting the audit', 6);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5020, 0, 'REQUESTED_BY_USER_NAME', 'Requested by user name', 'The name of the user requesting the audit', 7);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5020, 0, 'REQUESTED_BY_USER_FRIENDLY_NAME', 'Requested by user friendly name', 'The friendly name of the user requesting the audit', 8);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5020, 0, 'REQUESTED_BY_USER_EMAIL', 'Requested by user email', 'The email of the user requesting the audit', 9);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5020, 0, 'AUDIT_REQUEST_LINK', 'Audit request link', 'A hyperlink to the audit request', 10);

DECLARE
	v_default_alert_frame_id	NUMBER;
BEGIN
	SELECT MAX (default_alert_frame_id) INTO v_default_alert_frame_id FROM CSR.default_alert_frame;
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (5020, v_default_alert_frame_id, 'automatic');
END;
/

CREATE OR REPLACE PROCEDURE chain.temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2,
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER
)
AS
	v_count						NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;

	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND (
				(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 1 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
			 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
		   );

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;

	INSERT INTO capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);

END;
/

-- New chain capabilities
BEGIN
	security.user_pkg.logonadmin;
	
	BEGIN
		--chain.chain_pkg.CREATE_AUDIT_REQUESTS
		chain.temp_RegisterCapability(2 /*chain.chain_pkg.CT_SUPPLIERS*/, 'Request audits', 1 /*chain.chain_pkg.BOOLEAN_PERMISSION*/, 1 /*chain.chain_pkg.IS_SUPPLIER_CAPABILITY*/);
	--EXCEPTION
	--	WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	BEGIN
		--chain.chain_pkg.CREATE_SUPPLIER_AUDIT
		chain.temp_RegisterCapability(2 /*chain.chain_pkg.CT_SUPPLIERS*/, 'Create supplier audit', 1 /*chain.chain_pkg.BOOLEAN_PERMISSION*/, 1 /*chain.chain_pkg.IS_SUPPLIER_CAPABILITY*/);
	--EXCEPTION
	--	WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;
END;
/

-- resync flow state role capabilities to add the default permission sets for any new ones
-- copied from utils\fixMissingFlowCapabilites.sql
BEGIN
	-- roles
	FOR r IN (
		SELECT f.app_sid, fs.flow_state_id, fc.flow_capability_id, fsr.role_sid, fc.default_permission_set
		  FROM csr.flow f
		  JOIN csr.flow_state fs
			ON f.flow_sid = fs.flow_sid
		  JOIN csr.flow_capability fc
			ON f.flow_alert_class = fc.flow_alert_class
		  JOIN csr.flow_state_role fsr
			ON fs.flow_state_id = fsr.flow_state_id AND fs.app_sid = fsr.app_sid
		  LEFT JOIN csr.flow_state_role_capability fsrc -- exclude existing capabilities
		    ON fsrc.app_sid = f.app_sid AND fsrc.flow_state_id = fs.flow_state_id 
		   AND fsrc.flow_capability_id = fc.flow_capability_id 
		   AND fsrc.role_sid = fsr.role_sid 
		 WHERE fsrc.flow_state_rl_cap_id IS NULL
	) LOOP
		BEGIN
			INSERT INTO csr.flow_state_role_capability (app_sid, flow_state_rl_cap_id, flow_state_id, flow_capability_id, role_sid, flow_involvement_type_id, permission_set)
			   VALUES (r.app_sid, csr.flow_state_rl_cap_id_seq.NEXTVAL, r.flow_state_id, r.flow_capability_id, r.role_sid, null, 0);
		EXCEPTION
			WHEN dup_val_on_index THEN
				-- already an existing capability
				NULL;
		END;
	END LOOP;
	
	-- involvements
	FOR r IN (
		SELECT f.app_sid, fs.flow_state_id, fc.flow_capability_id, fsi.flow_involvement_type_id, fc.default_permission_set
		  FROM csr.flow f
		  JOIN csr.flow_state fs
			ON f.flow_sid = fs.flow_sid
		  JOIN csr.flow_capability fc
			ON f.flow_alert_class = fc.flow_alert_class
		  JOIN csr.flow_state_involvement fsi
			ON fs.flow_state_id = fsi.flow_state_id AND fs.app_sid = fsi.app_sid
		  LEFT JOIN csr.flow_state_role_capability fsrc -- exclude existing capabilities
		    ON fsrc.app_sid = f.app_sid AND fsrc.flow_state_id = fs.flow_state_id 
		   AND fsrc.flow_capability_id = fc.flow_capability_id 
		   AND fsrc.flow_involvement_type_id = fsi.flow_involvement_type_id 
		 WHERE fsrc.flow_state_rl_cap_id IS NULL
	) LOOP
		BEGIN
			INSERT INTO csr.flow_state_role_capability (app_sid, flow_state_rl_cap_id, flow_state_id, flow_capability_id, role_sid, flow_involvement_type_id, permission_set)
			   VALUES (r.app_sid, csr.flow_state_rl_cap_id_seq.NEXTVAL, r.flow_state_id, r.flow_capability_id, null, r.flow_involvement_type_id, 0);
		EXCEPTION
			WHEN dup_val_on_index THEN
				-- already an existing capability
				NULL;
		END;
	END LOOP;
END;
/

-- set expired audits
UPDATE csr.internal_audit
   SET expired = 1
 WHERE internal_audit_sid IN (
	SELECT internal_audit_sid
	  FROM csr.internal_audit ia
	  JOIN csr.audit_closure_type act
		ON ia.audit_closure_type_id = act.audit_closure_type_id
	 WHERE CASE (act.re_audit_due_after_type)
			WHEN 'd' THEN ia.audit_dtm + act.re_audit_due_after
			WHEN 'w' THEN ia.audit_dtm + (act.re_audit_due_after*7)
			WHEN 'm' THEN ADD_MONTHS(ia.audit_dtm, act.re_audit_due_after)
			WHEN 'y' THEN ADD_MONTHS(ia.audit_dtm, act.re_audit_due_after*12)
		END < SYSDATE
);

-- ** New package grants **
create or replace package chain.audit_request_pkg
is
	procedure dummy;
end;
/
create or replace package body chain.audit_request_pkg
is
	procedure dummy
	as begin null; end;
end;
/

grant execute on chain.audit_request_pkg to web_user;

DROP PACKAGE chain.temp_message_pkg;
DROP PROCEDURE chain.temp_RegisterCapability;


-- *** Packages ***
@../chain/chain_pkg
@../chain/chain_link_pkg
@../chain/message_pkg
@../chain/audit_request_pkg
@../audit_pkg
@../flow_pkg
@../chain/plugin_pkg
@../chain/flow_form_pkg
@../chain/setup_pkg

@../chain/company_body
@../chain/chain_link_body
@../chain/message_body
@../chain/audit_request_body
@../chain/company_type_body
@../audit_body
@../quick_survey_body
@../campaign_body
@../property_body
@../chain/plugin_body
@../chain/invitation_body
@../chain/company_filter_body
@../chain/flow_form_body
@../chain/supplier_flow_body
@../csrimp/imp_body
@../chain/setup_body
@../chain/chain_body
@../chain/supplier_audit_body
@../schema_body
@../supplier_body
@../flow_body
@../csr_data_body

@update_tail
