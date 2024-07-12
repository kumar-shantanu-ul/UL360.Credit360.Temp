-- Please update version.sql too -- this keeps clean builds in sync
define version=2663
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.supplier_score_log ADD (
	valid_until_dtm					DATE
);

ALTER TABLE csrimp.supplier_score_log ADD (
	valid_until_dtm					DATE
);

ALTER TABLE csr.non_compliance ADD (
	root_cause						CLOB
);

ALTER TABLE csrimp.non_compliance ADD (
	root_cause						CLOB
);

ALTER TABLE csr.non_compliance_type ADD (
	root_cause_enabled				NUMBER(1) DEFAULT 0,
	CONSTRAINT chk_non_comp_typ_rt_cause_1_0 CHECK (root_cause_enabled IN (1, 0))
);

UPDATE csr.non_compliance_type SET root_cause_enabled = 0;
ALTER TABLE csr.non_compliance_type MODIFY root_cause_enabled NOT NULL;

ALTER TABLE csrimp.non_compliance_type ADD (
	root_cause_enabled				NUMBER(1),
	CONSTRAINT chk_non_comp_typ_rt_cause_1_0 CHECK (root_cause_enabled IN (1, 0))
);

UPDATE csrimp.non_compliance_type SET root_cause_enabled = 0;
ALTER TABLE csrimp.non_compliance_type MODIFY root_cause_enabled NOT NULL;

GRANT CREATE TABLE TO csr;
create index csr.ix_non_comp_rt_cse_search on csr.non_compliance(root_cause) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');
REVOKE CREATE TABLE FROM csr;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
CREATE OR REPLACE VIEW csr.v$supplier_score AS
	SELECT css.app_sid, css.company_sid, css.score_type_id, css.last_supplier_score_id,
		   ss.score, ss.set_dtm score_last_changed, ss.score_threshold_id, 
		   ss.changed_by_user_sid, cu.full_name changed_by_user_full_name, ss.comment_text,
		   st.description score_threshold_description, t.label score_type_label, t.pos,
		   t.format_mask, ss.valid_until_dtm, CASE WHEN ss.valid_until_dtm IS NULL OR ss.valid_until_dtm >= SYSDATE THEN 1 ELSE 0 END valid
	  FROM csr.current_supplier_score css
	  JOIN csr.supplier_score_log ss ON css.company_sid = ss.supplier_sid AND css.last_supplier_score_id = ss.supplier_score_id
	  LEFT JOIN csr.score_threshold st ON ss.score_threshold_id = st.score_threshold_id
	  JOIN csr.score_type t ON css.score_type_id = t.score_type_id
	  LEFT JOIN csr.csr_user cu ON ss.changed_by_user_sid = cu.csr_user_sid;


-- *** Data changes ***
-- RLS

-- Data

DECLARE
    job BINARY_INTEGER;
BEGIN
	 DBMS_SCHEDULER.DROP_JOB (
       job_name             => 'csr.audit_text'
    );
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

-- ** New package grants **

-- *** Packages ***
@..\supplier_pkg
@..\audit_pkg

@..\schema_body
@..\csrimp\imp_body
@..\audit_body
@..\issue_body
@..\non_compliance_report_body
@..\supplier_body
@..\chain\company_body

@update_tail
