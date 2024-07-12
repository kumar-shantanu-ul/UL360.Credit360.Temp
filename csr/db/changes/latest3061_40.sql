-- Please update version.sql too -- this keeps clean builds in sync
define version=3061
define minor_version=40
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE csr.tpl_report_tag_qchart
(
    app_sid NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL, 
	tpl_report_tag_qchart_id NUMBER(10,0) NOT NULL, 
	month_offset NUMBER(10,0) DEFAULT -12 NOT NULL, 
	month_duration NUMBER(10,0) DEFAULT 12 NOT NULL, 
	period_set_id NUMBER(10,0) NOT NULL, 
	period_interval_id NUMBER(10,0) NOT NULL, 
	hide_if_empty NUMBER(1,0) DEFAULT 0 NOT NULL, 
	split_table_by_columns NUMBER(10,0) DEFAULT 0 NOT NULL, 
	saved_filter_sid NUMBER(10,0), 
    CONSTRAINT pk_tpl_report_tag_qchart PRIMARY KEY (app_sid, tpl_report_tag_qchart_id),
    CONSTRAINT fk_tpl_rp_tg_qc_period_int
        FOREIGN KEY (app_sid, period_set_id, period_interval_id)
        REFERENCES csr.period_interval(app_sid, period_set_id, period_interval_id),
    CONSTRAINT fk_tpl_rprt_tag_qc_saved_fltr 
        FOREIGN KEY (app_sid, saved_filter_sid)
	    REFERENCES chain.saved_filter (app_sid, saved_filter_sid)
);

CREATE TABLE csrimp.tpl_report_tag_qchart
(
    csrimp_session_id NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	tpl_report_tag_qchart_id NUMBER(10,0) NOT NULL, 
	month_offset NUMBER(10,0) NOT NULL, 
	month_duration NUMBER(10,0) NOT NULL, 
	period_set_id NUMBER(10,0) NOT NULL, 
	period_interval_id NUMBER(10,0) NOT NULL, 
	hide_if_empty NUMBER(1,0) NOT NULL, 
	split_table_by_columns NUMBER(10,0) NOT NULL, 
	saved_filter_sid NUMBER(10,0), 
    CONSTRAINT pk_tpl_report_tag_qchart PRIMARY KEY (csrimp_session_id, tpl_report_tag_qchart_id),
    CONSTRAINT fk_tpl_rep_tag_qc_is FOREIGN KEY
    	(csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_tpl_report_tag_qc (
	csrimp_session_id               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_tpl_report_tag_qc_id		NUMBER(10)	NOT NULL,
	new_tpl_report_tag_qc_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_tpl_report_tag_qc primary key (csrimp_session_id, old_tpl_report_tag_qc_id) USING INDEX,
	CONSTRAINT uk_map_tpl_report_tag_qc unique (csrimp_session_id, new_tpl_report_tag_qc_id) USING INDEX,
    CONSTRAINT fk_map_tpl_rep_tag_qc_is FOREIGN KEY
    	(csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

-- Alter tables

ALTER TABLE csr.tpl_report_tag 
    ADD TPL_REPORT_TAG_QC_ID NUMBER(10,0);

ALTER TABLE csr.tpl_report_tag 
    ADD CONSTRAINT fk_tpl_report_tag_qc_data 
        FOREIGN KEY (app_sid, tpl_report_tag_qc_id)
	    REFERENCES csr.tpl_report_tag_qchart (app_sid, tpl_report_tag_qchart_id) DEFERRABLE INITIALLY DEFERRED;


CREATE SEQUENCE csr.tpl_report_tag_qc_id_seq;

ALTER TABLE csrimp.tpl_report_tag 
    ADD tpl_report_tag_qc_id NUMBER(10,0);

CREATE index csr.ix_tpl_report_tag_trtqc on csr.TPL_REPORT_TAG(APP_SID, TPL_REPORT_TAG_QC_ID);

ALTER TABLE csr.tpl_report_tag DROP CONSTRAINT ct_tpl_report_tag;
ALTER TABLE csrimp.tpl_report_tag DROP CONSTRAINT ct_tpl_report_tag;

ALTER TABLE csr.tpl_report_tag ADD CONSTRAINT CT_TPL_REPORT_TAG CHECK (
    (tag_type IN (1,4,5) AND tpl_report_tag_ind_id IS NOT NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type = 6 AND tpl_report_tag_eval_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type IN (2,3,101) AND tpl_report_tag_dataview_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type = 7 AND tpl_report_tag_logging_form_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type = 8 AND tpl_rep_cust_tag_type_id IS NOT NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type = 9 AND tpl_report_tag_text_id IS NOT NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type = -1 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type = 10 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NOT NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type = 11 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NOT NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type = 102 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NOT NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type = 103 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NOT NULL AND tpl_report_tag_reg_data_id IS NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type = 12 AND tpl_report_tag_qc_id IS NOT NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
);

ALTER TABLE csrimp.tpl_report_tag ADD CONSTRAINT CT_TPL_REPORT_TAG CHECK (
    (tag_type IN (1,4,5) AND tpl_report_tag_ind_id IS NOT NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type = 6 AND tpl_report_tag_eval_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type IN (2,3,12,101) AND tpl_report_tag_dataview_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type = 7 AND tpl_report_tag_logging_form_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type = 8 AND tpl_rep_cust_tag_type_id IS NOT NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type = 9 AND tpl_report_tag_text_id IS NOT NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type = -1 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type = 10 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NOT NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type = 11 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NOT NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type = 102 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NOT NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type = 103 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NOT NULL AND tpl_report_tag_reg_data_id IS NULL AND tpl_report_tag_qc_id IS NULL)
    OR (tag_type = 12 AND tpl_report_tag_qc_id IS NOT NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
);


create index csr.ix_tpl_rep_qc_period_set_id on csr.tpl_report_tag_qchart (app_sid, period_set_id, period_interval_id);
create index csr.ix_tpl_rep_qc_saved_filt_id on csr.tpl_report_tag_qchart (app_sid, saved_filter_sid);

-- *** Grants ***
grant select on csr.tpl_report_tag_qc_id_seq to csrimp;
grant insert on csr.tpl_report_tag_qchart to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\templated_report_pkg
@..\schema_pkg

@..\templated_report_body
@..\schema_body
@..\csr_app_body
@..\csrimp\imp_body

@update_tail
