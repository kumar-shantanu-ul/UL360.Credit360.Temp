-- Please update version.sql too -- this keeps clean builds in sync
define version=2970
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.tpl_report_reg_data_type (
	tpl_report_reg_data_type_id 	NUMBER(10) NOT NULL,
    description						VARCHAR2(255) NOT NULL,
    pos								NUMBER(10) NOT NULL,
    CONSTRAINT pk_tpl_report_reg_data_type PRIMARY KEY (tpl_report_reg_data_type_id)
);

CREATE SEQUENCE csr.tpl_report_tag_reg_data_id_seq;

CREATE TABLE csr.tpl_report_tag_reg_data (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	tpl_report_tag_reg_data_id     	NUMBER(10) NOT NULL,
    tpl_report_reg_data_type_id		NUMBER(10) NOT NULL,
    CONSTRAINT pk_tpl_report_tag_reg_data PRIMARY KEY (app_sid, tpl_report_tag_reg_data_id),
    CONSTRAINT fk_tpl_report_reg_data_type FOREIGN KEY (tpl_report_reg_data_type_id) REFERENCES csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id)
);
CREATE INDEX csr.ix_tpl_report_ta_tpl_report_re ON csr.tpl_report_tag_reg_data (tpl_report_reg_data_type_id);

CREATE TABLE csrimp.tpl_report_tag_reg_data (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	tpl_report_tag_reg_data_id     	NUMBER(10) NOT NULL,
    tpl_report_reg_data_type_id		NUMBER(10) NOT NULL,
    CONSTRAINT pk_tpl_report_tag_reg_data PRIMARY KEY (csrimp_session_id, tpl_report_tag_reg_data_id),
    CONSTRAINT fk_tpl_report_tag_reg_data_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE TABLE csrimp.map_tpl_report_tag_reg_data (
	csrimp_session_id					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_tpl_report_tag_reg_data_id		NUMBER(10)	NOT NULL,
	new_tpl_report_tag_reg_data_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_tpl_report_tag_reg_data PRIMARY KEY (csrimp_session_id, old_tpl_report_tag_reg_data_id) USING INDEX,
	CONSTRAINT uk_map_tpl_report_tag_reg_data UNIQUE (csrimp_session_id, new_tpl_report_tag_reg_data_id) USING INDEX,
	CONSTRAINT fk_map_tpl_rep_tag_reg_data_is FOREIGN KEY
		(csrimp_session_id) REFERENCES CSRIMP.CSRIMP_SESSION (csrimp_session_id)
		ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE csr.tpl_report_tag ADD (
	tpl_report_tag_reg_data_id		NUMBER(10),
    CONSTRAINT fk_tpl_report_tag_reg_data
    	FOREIGN KEY (app_sid, tpl_report_tag_reg_data_id)
    	REFERENCES csr.tpl_report_tag_reg_data(app_sid, tpl_report_tag_reg_data_id) DEFERRABLE INITIALLY DEFERRED
);
CREATE INDEX csr.ix_tpl_report_ta_tpl_report_rg ON csr.tpl_report_tag (app_sid, tpl_report_tag_reg_data_id);

ALTER TABLE csrimp.tpl_report_tag ADD (
	tpl_report_tag_reg_data_id		NUMBER(10)
);

ALTER TABLE csr.tpl_report_tag DROP CONSTRAINT ct_tpl_report_tag;
ALTER TABLE csrimp.tpl_report_tag DROP CONSTRAINT ct_tpl_report_tag;

ALTER TABLE csr.tpl_report_tag ADD CONSTRAINT CT_TPL_REPORT_TAG CHECK (
    (tag_type IN (1,4,5) AND tpl_report_tag_ind_id IS NOT NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 6 AND tpl_report_tag_eval_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type IN (2,3,101) AND tpl_report_tag_dataview_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 7 AND tpl_report_tag_logging_form_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 8 AND tpl_rep_cust_tag_type_id IS NOT NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 9 AND tpl_report_tag_text_id IS NOT NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = -1 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 10 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NOT NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 11 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NOT NULL)
    OR (tag_type = 102 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NOT NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 103 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NOT NULL AND tpl_report_tag_reg_data_id IS NULL)
);

ALTER TABLE csrimp.tpl_report_tag ADD CONSTRAINT CT_TPL_REPORT_TAG CHECK (
    (tag_type IN (1,4,5) AND tpl_report_tag_ind_id IS NOT NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 6 AND tpl_report_tag_eval_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type IN (2,3,101) AND tpl_report_tag_dataview_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 7 AND tpl_report_tag_logging_form_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 8 AND tpl_rep_cust_tag_type_id IS NOT NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 9 AND tpl_report_tag_text_id IS NOT NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = -1 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 10 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NOT NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 11 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NOT NULL)
    OR (tag_type = 102 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NOT NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 103 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NOT NULL AND tpl_report_tag_reg_data_id IS NULL)
);

-- *** Grants ***
GRANT SELECT ON csr.tpl_report_tag_reg_data_id_seq TO csrimp;
GRANT INSERT ON csr.tpl_report_tag_reg_data TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.tpl_report_tag_reg_data TO tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos) VALUES ( 1, 'Fund', 1);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos) VALUES ( 2, 'Management company', 2);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos) VALUES ( 3, 'Management company contact', 3);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos) VALUES ( 4, 'Meter number', 4);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos) VALUES ( 5, 'Meter type', 5);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos) VALUES ( 6, 'Property address', 6);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos) VALUES ( 7, 'Property subtype', 7);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos) VALUES ( 8, 'Property type', 8);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos) VALUES ( 9, 'Region image', 9);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos) VALUES (10, 'Region reference', 10);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../templated_report_pkg
@../templated_report_body

@../csr_app_body
@../csrimp/imp_body
@../schema_pkg
@../schema_body

@update_tail
