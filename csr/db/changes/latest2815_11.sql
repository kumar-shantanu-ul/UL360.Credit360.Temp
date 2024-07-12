-- Please update version.sql too -- this keeps clean builds in sync
define version=2815
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
CREATE INDEX csr.ix_ind_lookup_key ON csr.ind(app_sid, lookup_key);

BEGIN
	FOR chk IN (
		SELECT * FROM dual WHERE NOT EXISTS (
			SELECT * FROM all_indexes WHERE owner='CSR' AND index_name = 'IDX_NON_COMP_REGION'
		)
	) LOOP
		EXECUTE IMMEDIATE 'create index csr.idx_non_comp_region on csr.NON_COMPLIANCE(APP_SID, REGION_SID)';
	END LOOP;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

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
								ctx_ddl.optimize_index(''ix_section_title_search'', ctx_ddl.OPTLEVEL_FULL);',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2015/01/03 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=WEEKLY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise all CSR text indexes');
       COMMIT;
END;
/

-- optimise job -- run weekly (at the weekend)
-- do one job for all so they aren't running at the same time
DECLARE
    job BINARY_INTEGER;
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'chain.optimize_all_indexes',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.optimize_index(''ix_file_upload_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_activity_desc_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_activity_loc_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_activity_out_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_activity_log_search'', ctx_ddl.OPTLEVEL_FULL);',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2015/01/03 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=WEEKLY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise all CHAIN text indexes');
       COMMIT;
END;
/

-- ** New package grants **

-- *** Packages ***

@update_tail
