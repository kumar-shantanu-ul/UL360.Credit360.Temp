-- Please update version.sql too -- this keeps clean builds in sync
define version=773
@update_header

grant select, references on cms.tab to csr;
grant select, references on cms.form to csr;
grant select, references on cms.filter to csr;

CREATE SEQUENCE CSR.TPL_REPORT_TAG_LOGGING_FRM_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

ALTER TABLE CSR.TPL_REPORT_TAG DROP CONSTRAINT CT_TPL_REPORT_TAG;

ALTER TABLE CSR.TPL_REPORT_TAG ADD (
	TPL_REPORT_TAG_LOGGING_FORM_ID NUMBER(10, 0),
	CONSTRAINT CT_TPL_REPORT_TAG CHECK ((tag_type IN (1,4,5) AND tpl_report_tag_ind_id IS NOT NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL)
OR (tag_type = 6 AND tpl_report_tag_eval_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL)
OR (tag_type IN (2,3) AND tpl_report_tag_dataview_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL)
OR (tag_type = 7 AND tpl_report_tag_logging_form_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL))
);

CREATE TABLE CSR.TPL_REPORT_TAG_LOGGING_FORM(
    APP_SID                           NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    TPL_REPORT_TAG_LOGGING_FORM_ID    NUMBER(10, 0)    NOT NULL,
    TAB_SID                           NUMBER(10, 0)    NOT NULL,
    MONTH_OFFSET                      NUMBER(10, 0)    NOT NULL,
    REGION_COLUMN_NAME                VARCHAR2(30),
    TPL_REGION_TYPE_ID                NUMBER(10, 0),
    DATE_COLUMN_NAME                  VARCHAR2(30),
    FORM_SID                          NUMBER(10, 0),
    FILTER_SID                        NUMBER(10, 0),
    CONSTRAINT CHK_TPL_REP_LGN_FORM_FILTER CHECK (form_sid IS NULL OR filter_sid IS NULL),
    CONSTRAINT PK_TPL_REP_TAG_LOGGING_FORM PRIMARY KEY (APP_SID, TPL_REPORT_TAG_LOGGING_FORM_ID)
)
;

ALTER TABLE CSR.TPL_REPORT_TAG ADD CONSTRAINT FK_TPL_REP_TAG_LGN_FRM 
    FOREIGN KEY (APP_SID, TPL_REPORT_TAG_LOGGING_FORM_ID)
    REFERENCES CSR.TPL_REPORT_TAG_LOGGING_FORM(APP_SID, TPL_REPORT_TAG_LOGGING_FORM_ID) DEFERRABLE INITIALLY DEFERRED
;

ALTER TABLE CSR.TPL_REPORT_TAG_LOGGING_FORM ADD CONSTRAINT FK_TPL_REP_TAG_LGN_FRM_TAB_SID 
    FOREIGN KEY (APP_SID, TAB_SID)
    REFERENCES CMS.TAB(APP_SID, TAB_SID)
;

ALTER TABLE CSR.TPL_REPORT_TAG_LOGGING_FORM ADD CONSTRAINT FK_TPL_REP_TAG_LGN_FRM_FRM_SID 
    FOREIGN KEY (APP_SID, FORM_SID)
    REFERENCES CMS.FORM(APP_SID, FORM_SID)
;

ALTER TABLE CSR.TPL_REPORT_TAG_LOGGING_FORM ADD CONSTRAINT FK_TPL_REP_TAG_LGN_FRM_FIL_SID 
    FOREIGN KEY (APP_SID, FILTER_SID)
    REFERENCES CMS.FILTER(APP_SID, FILTER_SID)
;

ALTER TABLE CSR.TPL_REPORT_TAG_LOGGING_FORM ADD CONSTRAINT RefTPL_REGION_TYPE2614 
    FOREIGN KEY (TPL_REGION_TYPE_ID)
    REFERENCES CSR.TPL_REGION_TYPE(TPL_REGION_TYPE_ID)
;

@..\templated_report_pkg
@..\templated_report_body



@update_tail
