-- Please update version.sql too -- this keeps clean builds in sync
define version=468
@update_header

connect actions/actions@&_CONNECT_IDENTIFIER
grant select, references on task to csr;
connect csr/csr@&_CONNECT_IDENTIFIER


CREATE SEQUENCE ISSUE_ACTION_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

ALTER TABLE ISSUE DROP CONSTRAINT CHK_ISSUE_FKS;

ALTER TABLE ISSUE ADD (
	ISSUE_ACTION_ID            NUMBER(10, 0),
	CONSTRAINT CHK_ISSUE_FKS CHECK (
		(ISSUE_PENDING_VAL_ID IS NOT NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_ACTION_ID IS NULL)
		OR
		(ISSUE_SHEET_VALUE_ID IS NOT NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_ACTION_ID IS NULL)
		OR
		(ISSUE_SURVEY_ANSWER_ID IS NOT NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_ACTION_ID IS NULL)
		OR
		(ISSUE_NON_COMPLIANCE_ID IS NOT NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL)
		OR
		(ISSUE_ACTION_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL)
		OR
		(ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_ACTION_ID IS NULL)
	)
);

CREATE TABLE ISSUE_ACTION(
    APP_SID            NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ISSUE_ACTION_ID    NUMBER(10, 0)    NOT NULL,
    TASK_SID           NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK777 PRIMARY KEY (APP_SID, ISSUE_ACTION_ID)
)
;

ALTER TABLE ISSUE ADD CONSTRAINT RefISSUE_ACTION1695 
    FOREIGN KEY (APP_SID, ISSUE_ACTION_ID)
    REFERENCES ISSUE_ACTION(APP_SID, ISSUE_ACTION_ID)
;

ALTER TABLE ISSUE_ACTION ADD CONSTRAINT RefCUSTOMER1696 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

ALTER TABLE ISSUE_ACTION ADD CONSTRAINT RefTASK1698 
    FOREIGN KEY (APP_SID, TASK_SID)
    REFERENCES ACTIONS.TASK(APP_SID, TASK_SID)
;

CREATE OR REPLACE VIEW v$issue AS
	SELECT i.app_sid, i.issue_id, i.label, note, i.source_label,
		   raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
		   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
		   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
		   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
		   sysdate now_dtm, due_dtm, ist.issue_type_Id, ist.label issue_type_label,
		   issue_pending_val_id, issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id,
		   CASE 
			WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND SYSDATE > due_dtm THEN 1
			ELSE 0 
		   END is_overdue
	  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user cuass
	 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
	   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
	   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+) 
	   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
	   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+)
;


-- Rebuild issues package
@../issue_pkg
@../issue_body


@update_tail
