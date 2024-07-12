-- Please update version.sql too -- this keeps clean builds in sync
define version=3404
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.tpl_report_tag_suggestion DROP CONSTRAINT chk_tpl_report_tag_suggestion;
ALTER TABLE csr.tpl_report_tag DROP CONSTRAINT fk_tpl_report_tag_suggestion;
ALTER TABLE csr.tpl_report_tag_suggestion DROP CONSTRAINT pk_tpl_report_tag_suggestion;
DROP TABLE csr.tpl_report_tag_suggestion;

ALTER TABLE csrimp.tpl_report_tag_suggestion DROP CONSTRAINT pk_tpl_report_tag_suggestion;
DROP TABLE csrimp.tpl_report_tag_suggestion;

ALTER TABLE csr.tpl_report_tag DROP CONSTRAINT ct_tpl_report_tag;
ALTER TABLE csr.tpl_report_tag DROP COLUMN tpl_report_tag_suggestion_id;
ALTER TABLE csr.tpl_report_tag ADD (
	CONSTRAINT ct_tpl_report_tag CHECK (
		(tag_type IN (1,4,5,14) AND tpl_report_tag_ind_id IS NOT NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 6 AND tpl_report_tag_eval_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type IN (2,3,101) AND tpl_report_tag_dataview_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 7 AND tpl_report_tag_logging_form_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 8 AND tpl_rep_cust_tag_type_id IS NOT NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 9 AND tpl_report_tag_text_id IS NOT NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = -1 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 10 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NOT NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 11 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NOT NULL)
		OR (tag_type = 102 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NOT NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 103 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NOT NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 12 AND TPL_REPORT_TAG_QC_ID IS NOT NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
	)
);

ALTER TABLE csrimp.tpl_report_tag DROP CONSTRAINT ct_tpl_report_tag;
ALTER TABLE csrimp.tpl_report_tag DROP COLUMN tpl_report_tag_suggestion_id;
ALTER TABLE csrimp.tpl_report_tag ADD (
	CONSTRAINT ct_tpl_report_tag CHECK (
		(tag_type IN (1,4,5,14) AND tpl_report_tag_ind_id IS NOT NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 6 AND tpl_report_tag_eval_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type IN (2,3,101) AND tpl_report_tag_dataview_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 7 AND tpl_report_tag_logging_form_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 8 AND tpl_rep_cust_tag_type_id IS NOT NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 9 AND tpl_report_tag_text_id IS NOT NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = -1 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 10 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NOT NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 11 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NOT NULL)
		OR (tag_type = 102 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NOT NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 103 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NOT NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 12 AND TPL_REPORT_TAG_QC_ID IS NOT NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
	)
);

DROP TABLE csrimp.map_tpl_report_tag_suggestion;

DROP SEQUENCE csr.tpl_report_tag_sugg_id_seq;

-- DROP suggestions schema
DROP USER suggestions CASCADE;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

BEGIN
	-- DELETE menu item
	FOR r IN (
		SELECT so.sid_id
		  FROM security.menu m
		  JOIN security.securable_object so ON m.sid_id = so.sid_id
		 WHERE description = 'Suggestions'
		   AND action = '/app/ui.suggestions/suggestions')
	LOOP
		DELETE FROM security.acl
		 WHERE acl_id = (SELECT dacl_id
						   FROM security.securable_object
						  WHERE sid_id = r.sid_id);

		DELETE FROM security.menu
		 WHERE sid_id = r.sid_id;

		DELETE FROM security.securable_object
		 WHERE sid_id = r.sid_id;
	END LOOP;

	-- DELETE ui.suggestions WR
	FOR r IN (
		SELECT so.sid_id, so.dacl_id
		  FROM security.securable_object so
		 WHERE so.name = 'ui.suggestions')
	LOOP
		DELETE FROM security.acl
		 WHERE acl_id = r.dacl_id;

		DELETE FROM security.web_resource
		 WHERE sid_id = r.sid_id;

		DELETE FROM security.securable_object
		 WHERE sid_id = r.sid_id;
	END LOOP;

	-- DELETE suggestions API WR
	FOR r IN (
		SELECT so.sid_id, so.dacl_id
		  FROM security.securable_object so
		 WHERE so.name = 'api.suggestions')
	LOOP
		DELETE FROM security.acl
		 WHERE acl_id = r.dacl_id;

		DELETE FROM security.web_resource
		 WHERE sid_id = r.sid_id;

		DELETE FROM security.securable_object
		 WHERE sid_id = r.sid_id;
	END LOOP;

	-- DELETE suggestions ui API WR
	FOR r IN (
		SELECT so.sid_id, so.dacl_id
		  FROM security.securable_object so
		 WHERE so.name = 'api.suggestions.reactui')
	LOOP
		DELETE FROM security.acl
		 WHERE acl_id = r.dacl_id;

		DELETE FROM security.web_resource
		 WHERE sid_id = r.sid_id;

		DELETE FROM security.securable_object
		 WHERE sid_id = r.sid_id;
	END LOOP;

	DELETE FROM csr.module
	 WHERE module_name = 'API Suggestions'
		OR module_name = 'Suggestions';
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../enable_body
@../schema_pkg
@../schema_body
@../templated_report_pkg
@../templated_report_body
@../enable_body
@../csrimp/imp_body

@update_tail
