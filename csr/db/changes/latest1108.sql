-- Please update version.sql too -- this keeps clean builds in sync
define version=1108
@update_header

CREATE SEQUENCE CSR.ISSUE_SUPPLIER_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;


ALTER TABLE CSR.ISSUE DROP CONSTRAINT CHK_ISSUE_FKS;

ALTER TABLE CSR.ISSUE ADD (
	ISSUE_SUPPLIER_ID             NUMBER(10, 0),
	CONSTRAINT CHK_ISSUE_FKS CHECK ((ISSUE_PENDING_VAL_ID IS NOT NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL)
		OR
		(ISSUE_SHEET_VALUE_ID IS NOT NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL)
		OR
		(ISSUE_SURVEY_ANSWER_ID IS NOT NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL)
		OR
		(ISSUE_NON_COMPLIANCE_ID IS NOT NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL)
		OR
		(ISSUE_ACTION_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL)
		OR
		(ISSUE_METER_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL)
		OR
		(ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL)
		OR
		(ISSUE_METER_ALARM_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL)
		OR
		(ISSUE_METER_RAW_DATA_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL)
		OR
		(ISSUE_METER_DATA_SOURCE_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL)
		OR
		(ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_SUPPLIER_ID IS NOT NULL))
);


CREATE TABLE CSR.ISSUE_SUPPLIER(
    APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ISSUE_SUPPLIER_ID    NUMBER(10, 0)    NOT NULL,
    SUPPLIER_SID         NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK1361 PRIMARY KEY (APP_SID, ISSUE_SUPPLIER_ID)
)
;

ALTER TABLE CSR.TPL_IMG MODIFY PATH NULL;

ALTER TABLE CSR.TPL_IMG ADD(
    IMAGE       BLOB,
    FILENAME    VARCHAR2(255),
    MIME_TYPE    VARCHAR2(255)
)
;

ALTER TABLE CSR.ISSUE ADD CONSTRAINT FK_ISS_ISS_SUP 
    FOREIGN KEY (APP_SID, ISSUE_SUPPLIER_ID)
    REFERENCES CSR.ISSUE_SUPPLIER(APP_SID, ISSUE_SUPPLIER_ID)
;

ALTER TABLE CSR.ISSUE_SUPPLIER ADD CONSTRAINT FK_ISS_SUP_APP 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;

ALTER TABLE CSR.ISSUE_SUPPLIER ADD CONSTRAINT FK_ISS_SUP_SUP 
    FOREIGN KEY (APP_SID, SUPPLIER_SID)
    REFERENCES CSR.SUPPLIER(APP_SID, SUPPLIER_SID)
;


ALTER TABLE CSR.TEMP_ISSUE_SEARCH ADD (
	ISSUE_SUPPLIER_ID 			NUMBER(10)
);

CREATE OR REPLACE VIEW csr.v$issue AS
	SELECT i.app_sid, i.issue_id, i.label, i.source_label, i.is_visible, i.source_url, i.region_sid, i.owner_role_sid, i.owner_user_sid,
		   raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
		   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
		   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
		   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
		   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
		   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
		   sysdate now_dtm, due_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, i.issue_priority_id, ip.due_date_offset, CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, i.first_priority_set_dtm,
		   issue_pending_val_id, issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id, issue_supplier_id,
		   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND rejected_by_user_sid IS NULL AND SYSDATE > due_dtm THEN 1 ELSE 0 
		   END is_overdue,
		   CASE WHEN rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID') OR i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0 
		   END is_owner,
		   CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1
		   END is_resolved,
		   CASE WHEN i.closed_dtm IS NULL THEN 0 ELSE 1
		   END is_closed,
		   CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1
		   END is_rejected,
		   CASE  
			WHEN i.closed_dtm IS NOT NULL THEN 'Closed'
			WHEN i.resolved_dtm IS NOT NULL THEN 'Resolved'
			ELSE 'Ongoing'
		   END status
	  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, role r, correspondent c, issue_priority ip,
	       (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm
	 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
	   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
	   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+) 
	   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
	   AND i.app_sid = curej.app_sid(+) AND i.rejected_by_user_sid = curej.csr_user_sid(+)
	   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+)
	   AND i.app_sid = r.app_sid(+) AND i.assigned_to_role_sid = r.role_sid(+)
	   AND i.app_sid = c.app_sid(+) AND i.correspondent_id = c.correspondent_id(+)
	   AND i.app_sid = ip.app_sid(+) AND i.issue_priority_id = ip.issue_priority_id(+)
	   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+)
	   AND i.deleted = 0
	   AND (i.issue_non_compliance_id IS NULL OR i.issue_non_compliance_id NOT IN (
		-- filter out issues from deleted audits
		SELECT inc.issue_non_compliance_id
		  FROM issue_non_compliance inc
		  JOIN non_compliance nc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
		  JOIN customer c ON inc.app_sid = c.app_sid
		  JOIN security.securable_object so ON nc.internal_audit_sid = so.sid_id
		 WHERE so.parent_sid_id = c.trash_sid
	   ));

grant select, insert on csr.issue_type to chain;

-- From exec card_pkg.dumpcard('Chain.Cards.IssuesBrowser');
DECLARE
v_card_id         chain.card.card_id%TYPE;
v_desc            chain.card.description%TYPE;
v_class           chain.card.class_type%TYPE;
v_js_path         chain.card.js_include%TYPE;
v_js_class        chain.card.js_class_type%TYPE;
v_css_path        chain.card.css_include%TYPE;
v_actions         chain.T_STRING_LIST;
BEGIN
-- Chain.Cards.IssuesBrowser
v_desc := 'Displays tasks for a particular supplier';
v_class := 'Credit360.Chain.Cards.IssuesBrowser';
v_js_path := '/csr/site/chain/cards/issuesBrowser.js';
v_js_class := 'Chain.Cards.IssuesBrowser';
v_css_path := '';
BEGIN
INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
RETURNING card_id INTO v_card_id;
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
UPDATE chain.card
SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
WHERE js_class_type = v_js_class
RETURNING card_id INTO v_card_id;
END;
DELETE FROM chain.card_progression_action
WHERE card_id = v_card_id
AND action NOT IN ('default');
v_actions := chain.T_STRING_LIST('default');
FOR i IN v_actions.FIRST .. v_actions.LAST
LOOP
BEGIN
INSERT INTO chain.card_progression_action (card_id, action)
VALUES (v_card_id, v_actions(i));
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
NULL;
END;
END LOOP;
END;
/

@..\csr_data_pkg
@..\templated_report_pkg
@..\supplier_pkg
@..\issue_pkg
@..\chain\setup_pkg

@..\templated_report_body
@..\supplier_body
@..\issue_body
@..\chain\setup_body

@update_tail
