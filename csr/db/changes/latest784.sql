-- Please update version.sql too -- this keeps clean builds in sync
define version=784
@update_header

CREATE TABLE CSR.TPL_REP_CUST_TAG_TYPE
(
	APP_SID						NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	TPL_REP_CUST_TAG_TYPE_ID	NUMBER(10) NOT NULL,
	CS_CLASS					VARCHAR2(255) NOT NULL,
	JS_INCLUDE					VARCHAR2(255),
	JS_CLASS					VARCHAR2(255) NOT NULL,
	HELPER_PKG					VARCHAR2(255),
	DESCRIPTION					VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_TPL_REP_CUST_TAG_TYPE PRIMARY KEY (APP_SID, TPL_REP_CUST_TAG_TYPE_ID)
);

ALTER TABLE CSR.TPL_REPORT_TAG DROP CONSTRAINT CT_TPL_REPORT_TAG;

ALTER TABLE CSR.TPL_REPORT_TAG ADD (
	TPL_REP_CUST_TAG_TYPE_ID NUMBER(10, 0),
	CONSTRAINT FK_TPL_REPORT_TAG_CUST_TAG_TYP FOREIGN KEY (app_sid, tpl_rep_cust_tag_type_id) REFERENCES csr.tpl_rep_cust_tag_type(app_sid, tpl_rep_cust_tag_type_id),
	CONSTRAINT CT_TPL_REPORT_TAG CHECK ((tag_type IN (1,4,5) AND tpl_report_tag_ind_id IS NOT NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL)
OR (tag_type = 6 AND tpl_report_tag_eval_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL)
OR (tag_type IN (2,3) AND tpl_report_tag_dataview_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL)
OR (tag_type = 7 AND tpl_report_tag_logging_form_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL)
OR (tag_type = 8 AND tpl_rep_cust_tag_type_id IS NOT NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL)
)
);

@..\templated_report_pkg
@..\templated_report_body

@update_tail
