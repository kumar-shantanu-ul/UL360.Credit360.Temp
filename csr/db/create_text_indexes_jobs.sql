-- reindex job -- index on commit is flaky
DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every mintue afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.doclib_text',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.sync_index(''ix_doc_search'');',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise doclib text indexes');
       COMMIT;
END;
/

DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every mintue afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.doclib_desc_text',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.sync_index(''ix_doc_desc_search'');',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2014/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise doclib text indexes');
       COMMIT;
END;
/

-- reindex job -- index on commit is flaky
DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every minute afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.file_upload_text',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.sync_index(''ix_file_upload_search'');',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise file upload text content indexes');
       COMMIT;
END;
/

-- reindex job -- index on commit is flaky
DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every minute afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.sheet_note_text',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.sync_index(''ix_sh_val_note_search'');',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise sheet note text indexes');
       COMMIT;
END;
/

-- reindex job -- index on commit is flaky
DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every minute afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.help_body_text',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.sync_index(''ix_help_body_search'');',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise body text indexes');
       COMMIT;
END;
/

-- reindex job -- index on commit is flaky
DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every minute afterwards
    -- 10g w/low_priority_job created
	DBMS_SCHEDULER.CREATE_JOB (
	   job_name             => 'csr.qs_response_file_text',
	   job_type             => 'PLSQL_BLOCK',
	   job_action           => 'ctx_ddl.sync_index(''ix_qs_response_file_srch'');',
	   job_class            => 'low_priority_job',
	   start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	   repeat_interval      => 'FREQ=MINUTELY',
	   enabled              => TRUE,
	   auto_drop            => FALSE,
	   comments             => 'Synchronise quick survey text indexes');
	   COMMIT;
END;
/

DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every minute afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.qs_answer_text',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.sync_index(''ix_qs_ans_ans_search'');',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise survey answer text indexes');
       COMMIT;
END;
/

DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every minute afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.issue_log_text',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.sync_index(''ix_issue_log_search'');ctx_ddl.sync_index(''ix_issue_search'');ctx_ddl.sync_index(''ix_issue_desc_search'');',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise issue text indexes');
       COMMIT;
END;
/

DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every minute afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.audit_text',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.sync_index(''ix_audit_label_search'');ctx_ddl.sync_index(''ix_audit_notes_search'');ctx_ddl.sync_index(''ix_non_comp_label_search'');ctx_ddl.sync_index(''ix_non_comp_detail_search'');ctx_ddl.sync_index(''ix_non_comp_rt_cse_search'');',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise audit and non-compliance text indexes');
       COMMIT;
END;
/

DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every minute afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.section_body_text',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.sync_index(''ix_section_body_search'');',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise section body text indexes');
       COMMIT;
END;
/

DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every minute afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.section_title_text',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.sync_index(''ix_section_title_search'');',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise section title text indexes');
       COMMIT;
END;
/

DECLARE
	job BINARY_INTEGER;
BEGIN
	-- now and every minute afterwards
	-- 10g w/low_priority_job created
	DBMS_SCHEDULER.CREATE_JOB (
		job_name			=> 'csr.compliance_item_text',
		job_type			=> 'PLSQL_BLOCK',
		job_action			=> 'ctx_ddl.sync_index(''ix_ci_title_search'');
								ctx_ddl.sync_index(''ix_ci_summary_search'');
								ctx_ddl.sync_index(''ix_ci_details_search'');
								ctx_ddl.sync_index(''ix_ci_ref_code_search'');
								ctx_ddl.sync_index(''ix_ci_usr_comment_search'');
								ctx_ddl.sync_index(''ix_ci_citation_search'');',
		job_class			=> 'low_priority_job',
		start_date			=> to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval		=> 'FREQ=MINUTELY',
		enabled				=> TRUE,
		auto_drop			=> FALSE,
		comments			=> 'Synchronise compliance item text indexes');
		COMMIT;
END;
/

DECLARE
	job BINARY_INTEGER;
BEGIN
	-- now and every minute afterwards
	-- 10g w/low_priority_job created
	DBMS_SCHEDULER.CREATE_JOB (
		job_name			=> 'csr.compliance_permit_item_text',
		job_type			=> 'PLSQL_BLOCK',
		job_action			=> 'ctx_ddl.sync_index(''ix_cp_title_search'');
								ctx_ddl.sync_index(''ix_cp_reference_search'');
								ctx_ddl.sync_index(''ix_cp_activity_details_search'');',
		job_class			=> 'low_priority_job',
		start_date			=> to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval		=> 'FREQ=MINUTELY',
		enabled				=> TRUE,
		auto_drop			=> FALSE,
		comments			=> 'Synchronise compliance permit item text indexes');
		COMMIT;
END;
/

-- optimise job -- run weekly (at the weekend)
-- do one job for all so they aren't running at the same time
DECLARE
    job BINARY_INTEGER;
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.optimize_all_indexes',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.optimize_index(''ix_doc_search'', ctx_ddl.OPTLEVEL_FULL);
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
								ctx_ddl.optimize_index(''ix_cp_activity_details_search'', ctx_ddl.OPTLEVEL_FULL);',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2015/01/03 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=WEEKLY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise all CSR text indexes');
       COMMIT;
END;
/
