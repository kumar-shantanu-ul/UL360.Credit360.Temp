-- Please update version.sql too -- this keeps clean builds in sync
define version=1126
@update_header

ALTER TABLE CSR.QS_EXPR_NON_COMPL_ACTION MODIFY TITLE VARCHAR2(2048);

ALTER TABLE CSR.QS_EXPR_NON_COMPL_ACTION ADD (
    DETAIL                         VARCHAR2(2048),
    SEND_EMAIL_ON_CREATION         NUMBER(1, 0)      DEFAULT 0 NOT NULL
)
;

ALTER TABLE CSR.ISSUE_SUPPLIER ADD (
	QS_EXPR_NON_COMPL_ACTION_ID    NUMBER(10, 0)
)
;

ALTER TABLE CSR.ISSUE_SUPPLIER ADD CONSTRAINT FK_ISS_SUP_NC_ACTION 
    FOREIGN KEY (APP_SID, QS_EXPR_NON_COMPL_ACTION_ID)
    REFERENCES CSR.QS_EXPR_NON_COMPL_ACTION(APP_SID, QS_EXPR_NON_COMPL_ACTION_ID)
;

ALTER TABLE CSR.ISSUE_SUPPLIER RENAME CONSTRAINT PK1361 TO PK_ISSUE_SUPPLIER;

CREATE INDEX CSR.IX_ISSUE_SUP_SUPPLIER ON CSR.ISSUE_SUPPLIER(APP_SID, SUPPLIER_SID)
;

CREATE UNIQUE INDEX CSR.UK_ISSUE_SUPPLIER_NC_ACTION ON CSR.ISSUE_SUPPLIER(APP_SID, SUPPLIER_SID, NVL(QS_EXPR_NON_COMPL_ACTION_ID,ISSUE_SUPPLIER_ID))
;

grant select, references on chain.supplier_follower to csr;

INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'REGION_DESCRIPTION', 'Region description', 'The description of the region relating to the issue, if there is one', 14);

INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'ISSUE_LABEL', 'Issue label', 'The label of the issue', 15);

@..\audit_pkg
@..\issue_pkg
@..\quick_survey_pkg
@..\supplier_pkg

@..\audit_body
@..\issue_body
@..\quick_survey_body
@..\supplier_body

@update_tail