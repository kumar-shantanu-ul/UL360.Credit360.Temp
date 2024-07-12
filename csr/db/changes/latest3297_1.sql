-- Please update version.sql too -- this keeps clean builds in sync
define version=3297
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
GRANT CREATE TABLE TO csr;

DROP INDEX csr.IX_CP_DETAILS_SEARCH;

ALTER TABLE csr.COMPLIANCE_PERMIT
DROP COLUMN DETAILS;

CREATE INDEX csr.IX_CP_ACTIVITY_DETAILS_SEARCH ON csr.COMPLIANCE_PERMIT(ACTIVITY_DETAILS) indextype is ctxsys.context;

REVOKE CREATE TABLE FROM csr;

DECLARE
BEGIN
	DBMS_SCHEDULER.SET_ATTRIBUTE (
			name			=> 'csr.compliance_permit_item_text',
			attribute		=> 'job_action',
			value			=> 'ctx_ddl.sync_index(''ix_cp_title_search'');
								ctx_ddl.sync_index(''ix_cp_reference_search'');
								ctx_ddl.sync_index(''ix_cp_activity_details_search'');'
			);

	DBMS_SCHEDULER.SET_ATTRIBUTE (
			name			=> 'csr.optimize_all_indexes',
			attribute		=> 'job_action',
			value			=> 'ctx_ddl.optimize_index(''ix_doc_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_doc_desc_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_file_upload_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_sh_val_note_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_help_body_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_qs_response_file_srch'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_qs_ans_ans_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_issue_log_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_issue_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_issue_desc_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_audit_label_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_audit_notes_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_non_comp_label_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_non_comp_detail_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_non_comp_rt_cse_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_section_body_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_section_title_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_ci_title_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_ci_summary_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_ci_details_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_ci_ref_code_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_ci_usr_comment_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_ci_citation_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_cp_title_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_cp_reference_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_cp_activity_details_search'', ctx_ddl.OPTLEVEL_FULL);'
			);
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../permit_pkg
@../permit_body
@../permit_data_import_pkg
@../permit_data_import_body
@../permit_report_body
@../schema_body
@../csrimp/imp_body

@update_tail
