-- Please update version.sql too -- this keeps clean builds in sync
define version=3057
define minor_version=23
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.compliance_permit ADD (
	date_created 	DATE DEFAULT SYSDATE NOT NULL,
	date_updated 	DATE,
	created_by		NUMBER(10)
);

ALTER TABLE csr.compliance_permit ADD CONSTRAINT fk_comp_permit_created_by
	FOREIGN KEY (app_sid, created_by) 
	REFERENCES csr.csr_user (app_sid, csr_user_sid);

ALTER TABLE csrimp.compliance_permit ADD (
	date_created 	DATE DEFAULT SYSDATE NOT NULL,
	date_updated 	DATE,
	created_by		NUMBER(10)
);

create index csr.ix_compliance_pe_created_by on csr.compliance_permit (app_sid, created_by);
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	v_desc := 'Compliance Permit Filter';
	v_class := 'Credit360.Compliance.Cards.PermitFilter';
	v_js_path := '/csr/site/compliance/filters/PermitFilter.js';
	v_js_class := 'Credit360.Compliance.Filters.PermitFilter';
	v_css_path := '';
	
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
			 VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		  RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			   SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
		  	 WHERE js_class_type = v_js_class
		 RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
		  WHERE card_id = v_card_id
		    AND action NOT IN ('default');
	
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
				 VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;
/

DECLARE
	v_card_id	NUMBER(10);
BEGIN
	security.user_pkg.LogonAdmin;
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
			 VALUES (58, 'Compliance Permit Filter', 'Allows filtering of permit items', 'csr.permit_report_pkg', '/csr/site/compliance/PermitList.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Compliance.Filters.PermitFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
			 VALUES (chain.filter_type_id_seq.NEXTVAL, 'Compliance Permit Filter', 'csr.permit_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/

BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		 VALUES (58, 1, 'Number of permits');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
		 VALUES (58, 1, 1, 'Permit item region');
END;
/

GRANT CREATE TABLE TO csr;

/* COMPLIANCE PERMIT TITLE INDEX */
create index csr.ix_cp_title_search on csr.compliance_permit(title) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* COMPLIANCE PERMIT REFERENCE INDEX */
create index csr.ix_cp_reference_search on csr.compliance_permit(permit_reference) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* COMPLIANCE PERMIT DETAILS INDEX */
create index csr.ix_cp_details_search on csr.compliance_permit(details) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

REVOKE CREATE TABLE FROM csr;

DECLARE
	job 	BINARY_INTEGER;
BEGIN
	-- now and every minute afterwards
	-- 10g w/low_priority_job created
	DBMS_SCHEDULER.CREATE_JOB (
		job_name			=> 'csr.compliance_permit_item_text',
		job_type			=> 'PLSQL_BLOCK',
		job_action			=> 'ctx_ddl.sync_index(''ix_cp_title_search'');
								ctx_ddl.sync_index(''ix_cp_reference_search'');
								ctx_ddl.sync_index(''ix_cp_details_search'');',
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
	job 	BINARY_INTEGER;
BEGIN
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
							ctx_ddl.optimize_index(''ix_cp_details_search'', ctx_ddl.OPTLEVEL_FULL);'
		);
		COMMIT;
END;
/

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.permit_report_pkg AS
    PROCEDURE dummy;
END;
/
CREATE OR REPLACE PACKAGE BODY csr.permit_report_pkg AS
    PROCEDURE dummy
    AS
    BEGIN
        NULL;
    END;
END;
/

GRANT EXECUTE ON csr.permit_report_pkg TO web_user;
GRANT EXECUTE ON csr.permit_report_pkg TO chain;

-- *** Conditional Packages ***

-- *** Packages ***
@@../chain/filter_pkg
@@../permit_report_pkg

@@../csrimp/imp_body
@@../enable_body
@@../schema_body
@@../csr_user_body
@@../permit_report_body


@update_tail
